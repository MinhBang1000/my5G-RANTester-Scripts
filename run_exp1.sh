#!/bin/bash
# Run: screen -L -Logfile output.txt ./run_experiments.sh

echo "Run connectivity tests"
for e in $(seq 1 2); do
    for c in 3; do
        echo "Run core $c tests (exec $e)"
        for w in 500 400 300 200 100; do
            for i in 1 3 5 7 9 11; do
                echo "Running experiment $i (w=$w)"
                # bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/run.sh) -c $c -e 1 -g $i -u $((100*$i)) -t 60 -w $w -v
                ./run.sh -c $c -e 1 -g $i -u $((100*$i)) -t 60 -w $w -v

                echo "Waiting for experiment $i (w=$w) to finish"
                sleep $((2*60))

                echo "Collecting experiment $i (w=$w) data"
                bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/capture_and_parse_logs.sh) my5grantester-logs-$e-$c-$w-$i.csv

                echo "Collecting experiment $i data from influxdb"
                docker exec influxdb sh -c "influx query 'from(bucket:\"database\") |> range(start:-5m)' --raw" > my5grantester-logs-influxdb-$e-$c-$w-$i.csv

                echo "Clear experiment $i (w=$w) environment"
                bash stop_only.sh
                docker image prune --filter="dangling=true" -f
                docker volume prune -f

                sleep 15
            done
        done
    done
done

echo "Cleaning environment"
sleep $((1*60))
bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/stop_and_clear.sh)
docker image prune -a -f
docker volume prune -f
sleep $((1*60))