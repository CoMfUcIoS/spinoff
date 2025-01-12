package function

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/hetznercloud/hcloud-go/v2/hcloud"
)

func getAPISecret(secretName string) (secretBytes []byte, err error) {
	// read from the openfaas secrets folder
	secretBytes, err = os.ReadFile("/var/openfaas/secrets/" + secretName)
	if err != nil {
		// read from the original location for backwards compatibility with openfaas <= 0.8.2
		secretBytes, err = os.ReadFile("/run/secrets/" + secretName)
	}

	return secretBytes, err
}

func Handle(w http.ResponseWriter, r *http.Request) {
	apiSecret, err := getAPISecret("secret-api-key")
	if err != nil {
		fmt.Printf(err.Error())
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("error getting token. Reason: %s", err.Error())))
		return
	}

	token := string(apiSecret)

	metricName := os.Getenv("metric_name")
	fmt.Printf("metricName: %s", metricName)

	metricThreshold := os.Getenv("metric_threshold")
	fmt.Printf("metricThreshold: %s", metricThreshold)
	mt, _ := strconv.Atoi(metricThreshold)

	lastMinutes := os.Getenv("last_minutes")
	fmt.Printf("lastMinutes: %s", lastMinutes)
	lm, _ := strconv.Atoi(lastMinutes)

	client := hcloud.NewClient(hcloud.WithToken(token))

	fmt.Println("Checking running servers...")

	servers, err := client.Server.AllWithOpts(context.Background(), hcloud.ServerListOpts{
		Status:   []hcloud.ServerStatus{hcloud.ServerStatusRunning},
		ListOpts: hcloud.ListOpts{LabelSelector: "managed-by=spinoff"},
	})
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("error retrieving servers. Reason: %s", err.Error())))
		return
	}

	if len(servers) == 0 {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf("No servers in running state.")))
		return
	}

	for _, server := range servers {
		metricIsBelow, err := metricIsBelow(client, server, metricName, mt, lm)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("unable to check metric. Reason: %s", err.Error())))
			return
		}

		if metricIsBelow {
			_, err := client.Server.Delete(context.Background(), server)
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				w.Write([]byte(fmt.Sprintf("failed to delete server. Reason: %s", err.Error())))
				return
			}
		}
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(fmt.Sprintf("Done")))
}

// Check if a given metric is below a given threshold
func metricIsBelow(c *hcloud.Client, server *hcloud.Server, metricName string, metricThreshold int, lastMinutes int) (bool, error) {
	fmt.Printf("Checking metrics for server %s\n", server.Name)

	now := time.Now()

	serverMetrics, _, err := c.Server.GetMetrics(context.Background(), server, hcloud.ServerGetMetricsOpts{
		Types: []hcloud.ServerMetricType{hcloud.ServerMetricCPU},
		Start: now.Add(time.Duration(-lastMinutes) * time.Minute),
		End:   now,
	})
	if err != nil {
		log.Fatalf("error retrieving metrics for server: %s\n", err)
		return false, err
	}

	metricKeyPairs := serverMetrics.TimeSeries[metricName]

	var avg float64
	sum := 0.0
	for _, metricKeyPair := range metricKeyPairs {
		fmt.Printf("Timestamp: %v, Value: %s\n", metricKeyPair.Timestamp, metricKeyPair.Value)
		val, err2 := strconv.ParseFloat(metricKeyPair.Value, 32)
		if err2 != nil {
			return false, err2
		}
		sum += val
	}

	avg = sum / float64(len(metricKeyPairs))
	fmt.Printf("avg: %v", avg)

	return avg < float64(metricThreshold), nil
}
