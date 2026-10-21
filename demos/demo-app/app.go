// 演示应用：练习监控、日志、链路追踪时用的靶子
//
// 接口
//
//	GET /healthz   健康检查
//	GET /readyz    就绪检查
//	GET /slow      人为制造约 2 秒延迟
//	GET /error     人为返回 500
//	GET /          正常请求，产生指标 + 日志
//	GET /metrics   Prometheus 抓取入口
//	POST /alerts   接收 Alertmanager / Grafana webhook
package main

import (
	"embed"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

//go:embed static
var staticFS embed.FS

var (
	requestCount = prometheus.NewCounterVec(
		prometheus.CounterOpts{Name: "demo_http_requests_total", Help: "HTTP requests"},
		[]string{"method", "path", "status"},
	)
	requestLatency = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "demo_http_request_duration_seconds",
			Help:    "HTTP request latency",
			Buckets: []float64{0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10},
		},
		[]string{"method", "path"},
	)
)

func init() {
	prometheus.MustRegister(requestCount, requestLatency)
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func (r *statusRecorder) Write(bytes []byte) (int, error) {
	if r.status == 0 {
		r.status = 200
	}
	return r.ResponseWriter.Write(bytes)
}

func instrument(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: 200}
		next(rec, req)
		path := req.URL.Path
		requestLatency.WithLabelValues(req.Method, path).Observe(time.Since(start).Seconds())
		requestCount.WithLabelValues(req.Method, path, fmt.Sprintf("%d", rec.status)).Inc()
	}
}

func main() {
	mux := http.NewServeMux()

	page, err := staticFS.ReadFile("static/index.html")
	if err != nil {
		log.Fatalf("read embedded index: %v", err)
	}

	assets := http.FileServer(http.FS(staticFS))
	mux.Handle("/static/", http.StripPrefix("/static/", assets))

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		log.Printf("trace_id=%s handled GET / page", fakeTraceID())
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Cache-Control", "no-store")
		_, _ = w.Write(page)
	})

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]any{"ok": true})
	})

	mux.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]any{"ok": true, "ready": true})
	})

	mux.HandleFunc("/slow", func(w http.ResponseWriter, r *http.Request) {
		delay := 1.5 + rand.Float64()
		time.Sleep(time.Duration(delay * float64(time.Second)))
		log.Printf("trace_id=%s slow endpoint hit, delay=%.2fs", fakeTraceID(), delay)
		writeJSON(w, 200, map[string]any{"ok": true, "delay": delay})
	})

	mux.HandleFunc("/error", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("trace_id=%s simulated server error", fakeTraceID())
		writeJSON(w, 500, map[string]any{"ok": false, "error": "simulated"})
	})

	mux.HandleFunc("/alerts", func(w http.ResponseWriter, r *http.Request) {
		var payload struct {
			Alerts []struct {
				Status string            `json:"status"`
				Labels map[string]string `json:"labels"`
			} `json:"alerts"`
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			writeJSON(w, 400, map[string]any{"error": "bad json"})
			return
		}
		for _, a := range payload.Alerts {
			log.Printf("ALERT status=%s alertname=%s instance=%s severity=%s",
				a.Status, a.Labels["alertname"], a.Labels["instance"], a.Labels["severity"])
		}
		writeJSON(w, 200, map[string]any{"received": len(payload.Alerts)})
	})

	// /metrics 由 prometheus 客户端库提供，和业务接口分开挂载
	http.Handle("/metrics", promhttp.Handler())
	http.Handle("/", instrument(mux.ServeHTTP))

	addr := ":8081"
	log.Printf("demo-app listening on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal(err)
	}
}

func writeJSON(w http.ResponseWriter, code int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(body)
}

func hostname() string {
	h, _ := os.Hostname()
	return h
}

// fakeTraceID 返回一个伪 trace id，方便在日志里串联请求
func fakeTraceID() string {
	return fmt.Sprintf("%032x", rand.Uint64()) + fmt.Sprintf("%032x", rand.Uint64())
}
