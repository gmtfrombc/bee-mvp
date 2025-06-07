#!/usr/bin/env -S deno run --allow-net --allow-env --allow-read

/**
 * AI Coaching Engine Performance Benchmark
 * Measures p95 latency and memory usage under load
 * Target: p95 < 1.2s, Memory < 40MB per instance
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.dart";

interface BenchmarkResult {
    totalRequests: number;
    successCount: number;
    errorCount: number;
    p50Latency: number;
    p95Latency: number;
    p99Latency: number;
    avgLatency: number;
    maxLatency: number;
    memoryUsage: Deno.MemoryUsage;
    throughput: number;
}

class CoachBenchmark {
    private latencies: number[] = [];
    private errors: string[] = [];
    private startTime: number = 0;

    async runLoadTest(
        concurrency: number = 10,
        duration: number = 30, // seconds
        targetUrl: string = "http://localhost:54321/functions/v1/ai-coaching-engine"
    ): Promise<BenchmarkResult> {
        console.log(`🚀 Starting load test: ${concurrency} concurrent users for ${duration}s`);

        this.startTime = Date.now();
        const endTime = this.startTime + (duration * 1000);

        const workers: Promise<void>[] = [];

        // Start concurrent workers
        for (let i = 0; i < concurrency; i++) {
            workers.push(this.workerLoop(i, endTime, targetUrl));
        }

        // Wait for all workers to complete
        await Promise.all(workers);

        return this.calculateResults(duration);
    }

    private async workerLoop(
        workerId: number,
        endTime: number,
        targetUrl: string
    ): Promise<void> {
        let requestCount = 0;

        while (Date.now() < endTime) {
            const startTime = performance.now();

            try {
                const response = await fetch(targetUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY') || 'mock-key'}`,
                    },
                    body: JSON.stringify({
                        message: `Benchmark test message ${requestCount} from worker ${workerId}`,
                        user_id: `bench-user-${workerId}`,
                        session_id: `bench-session-${workerId}-${Date.now()}`,
                    }),
                });

                const endTime = performance.now();
                const latency = endTime - startTime;

                if (response.ok) {
                    this.latencies.push(latency);
                    const data = await response.json();

                    // Validate response structure
                    if (!data.response || !data.session_id) {
                        this.errors.push(`Invalid response structure from worker ${workerId}`);
                    }
                } else {
                    this.errors.push(
                        `HTTP ${response.status} from worker ${workerId}: ${await response.text()}`
                    );
                }

                requestCount++;

                // Small delay between requests
                await new Promise(resolve => setTimeout(resolve, 50));

            } catch (error) {
                const endTime = performance.now();
                const latency = endTime - startTime;
                this.latencies.push(latency);
                this.errors.push(`Network error from worker ${workerId}: ${error.message}`);
            }
        }

        console.log(`✅ Worker ${workerId} completed ${requestCount} requests`);
    }

    private calculateResults(duration: number): BenchmarkResult {
        const sortedLatencies = [...this.latencies].sort((a, b) => a - b);
        const totalRequests = this.latencies.length;
        const successCount = totalRequests - this.errors.length;

        const p50Index = Math.floor(sortedLatencies.length * 0.5);
        const p95Index = Math.floor(sortedLatencies.length * 0.95);
        const p99Index = Math.floor(sortedLatencies.length * 0.99);

        const sum = sortedLatencies.reduce((acc, val) => acc + val, 0);
        const avgLatency = sum / sortedLatencies.length;

        return {
            totalRequests,
            successCount,
            errorCount: this.errors.length,
            p50Latency: sortedLatencies[p50Index] || 0,
            p95Latency: sortedLatencies[p95Index] || 0,
            p99Latency: sortedLatencies[p99Index] || 0,
            avgLatency,
            maxLatency: sortedLatencies[sortedLatencies.length - 1] || 0,
            memoryUsage: Deno.memoryUsage(),
            throughput: totalRequests / duration,
        };
    }

    printResults(results: BenchmarkResult): void {
        console.log('\n📊 BENCHMARK RESULTS');
        console.log('='.repeat(50));
        console.log(`Total Requests: ${results.totalRequests}`);
        console.log(`Success Rate: ${((results.successCount / results.totalRequests) * 100).toFixed(2)}%`);
        console.log(`Error Count: ${results.errorCount}`);

        console.log('\n⚡ LATENCY METRICS (ms)');
        console.log(`P50: ${results.p50Latency.toFixed(2)}ms`);
        console.log(`P95: ${results.p95Latency.toFixed(2)}ms ${results.p95Latency > 1200 ? '❌ EXCEEDS TARGET' : '✅'}`);
        console.log(`P99: ${results.p99Latency.toFixed(2)}ms`);
        console.log(`Avg: ${results.avgLatency.toFixed(2)}ms`);
        console.log(`Max: ${results.maxLatency.toFixed(2)}ms`);

        console.log('\n🔄 THROUGHPUT');
        console.log(`Requests/sec: ${results.throughput.toFixed(2)}`);

        console.log('\n💾 MEMORY USAGE');
        console.log(`RSS: ${(results.memoryUsage.rss / 1024 / 1024).toFixed(2)}MB`);
        console.log(`Heap Used: ${(results.memoryUsage.heapUsed / 1024 / 1024).toFixed(2)}MB`);
        console.log(`Heap Total: ${(results.memoryUsage.heapTotal / 1024 / 1024).toFixed(2)}MB`);
        console.log(`External: ${(results.memoryUsage.external / 1024 / 1024).toFixed(2)}MB`);

        // Memory budget check (40MB target)
        const totalMemoryMB = results.memoryUsage.rss / 1024 / 1024;
        console.log(`Memory Budget: ${totalMemoryMB > 40 ? '❌ EXCEEDS 40MB LIMIT' : '✅ WITHIN BUDGET'}`);

        if (results.errorCount > 0) {
            console.log('\n❌ ERRORS');
            this.errors.slice(0, 5).forEach(error => console.log(`  - ${error}`));
            if (this.errors.length > 5) {
                console.log(`  ... and ${this.errors.length - 5} more errors`);
            }
        }

        console.log('\n' + '='.repeat(50));
    }

    async runSingleTest(targetUrl?: string): Promise<void> {
        console.log('🧪 Running single request test...');

        const url = targetUrl || "http://localhost:54321/functions/v1/ai-coaching-engine";
        const startTime = performance.now();

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY') || 'mock-key'}`,
                },
                body: JSON.stringify({
                    message: "Hello coach, I need some motivation today!",
                    user_id: "bench-test-user",
                    session_id: `single-test-${Date.now()}`,
                }),
            });

            const endTime = performance.now();
            const latency = endTime - startTime;

            console.log(`✅ Response received in ${latency.toFixed(2)}ms`);
            console.log(`Status: ${response.status}`);

            if (response.ok) {
                const data = await response.json();
                console.log(`Response preview: ${data.response?.substring(0, 100)}...`);
            } else {
                console.log(`❌ Error: ${await response.text()}`);
            }

        } catch (error) {
            console.log(`❌ Network error: ${error.message}`);
        }
    }
}

// CLI Interface
if (import.meta.main) {
    const benchmark = new CoachBenchmark();
    const args = Deno.args;

    if (args.includes('--help') || args.includes('-h')) {
        console.log(`
AI Coaching Engine Benchmark Tool

Usage:
  deno run --allow-net --allow-env bench.ts [options]

Options:
  --single          Run single request test
  --load            Run load test (default)
  --concurrency N   Number of concurrent users (default: 10)
  --duration N      Test duration in seconds (default: 30)
  --url URL         Target URL (default: localhost)
  --help, -h        Show this help message

Examples:
  deno run --allow-net --allow-env bench.ts --single
  deno run --allow-net --allow-env bench.ts --load --concurrency 20 --duration 60
    `);
        Deno.exit(0);
    }

    if (args.includes('--single')) {
        const urlIndex = args.indexOf('--url');
        const targetUrl = urlIndex !== -1 ? args[urlIndex + 1] : undefined;
        await benchmark.runSingleTest(targetUrl);
    } else {
        const concurrencyIndex = args.indexOf('--concurrency');
        const durationIndex = args.indexOf('--duration');
        const urlIndex = args.indexOf('--url');

        const concurrency = concurrencyIndex !== -1 ? parseInt(args[concurrencyIndex + 1]) : 10;
        const duration = durationIndex !== -1 ? parseInt(args[durationIndex + 1]) : 30;
        const targetUrl = urlIndex !== -1 ? args[urlIndex + 1] : undefined;

        const results = await benchmark.runLoadTest(concurrency, duration, targetUrl);
        benchmark.printResults(results);

        // Exit with error code if benchmarks fail
        if (results.p95Latency > 1200 || (results.memoryUsage.rss / 1024 / 1024) > 40) {
            console.log('\n❌ Benchmark targets not met!');
            Deno.exit(1);
        } else {
            console.log('\n✅ All benchmark targets met!');
        }
    }
} 