package main

import (
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"
)

func TestGreeting(t *testing.T) {
	if got := greeting("ProbeLab"); got != "Hello, ProbeLab" {
		t.Fatalf("greeting = %q", got)
	}
}

// TestClickHouse checks that the workflow started ClickHouse and gave the
// tests its ports. It skips when CLICKHOUSE_HTTP_PORT is not set.
func TestClickHouse(t *testing.T) {
	httpPort := os.Getenv("CLICKHOUSE_HTTP_PORT")
	if httpPort == "" {
		t.Skip("CLICKHOUSE_HTTP_PORT is not set")
	}
	host := os.Getenv("CLICKHOUSE_HOST")

	resp, err := http.Get("http://" + net.JoinHostPort(host, httpPort) + "/ping")
	if err != nil {
		t.Fatalf("ping ClickHouse: %v", err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("read the ping answer: %v", err)
	}
	if strings.TrimSpace(string(body)) != "Ok." {
		t.Fatalf("ping answered %q", body)
	}

	conn, err := net.DialTimeout("tcp", net.JoinHostPort(host, os.Getenv("CLICKHOUSE_PORT")), 5*time.Second)
	if err != nil {
		t.Fatalf("connect to the native port: %v", err)
	}
	_ = conn.Close()
}
