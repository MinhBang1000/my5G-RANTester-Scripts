echo "Run throughtput tests"
# Run 15 times all throughput tests
for e in $(seq 1 16); do
    for c in 3; do # Core 1 or 3 => 1: Free5GC 3.0.6, and 3: Open5GS
        echo "Run core $c tests (exec $e)"
        for i in 1 2 4 6 8 10; do
            echo "Running experiment $i"
            # bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/run.sh) -c $c -e 2 -g $i -v
            bash ./run.sh -c $c -e 2 -g $i -v

            for j in $(seq 0 $(($i - 1))); do
                docker network connect coletordemetricas-dockerstats_coleta my5grantester$j 2>/dev/null || true
            done

            echo "Waiting connections for experiment $i"
            sleep $((1*60))

            echo "Starting experiment $i"
            # Open for Free5GC
            # for j in $(seq 0 $(($i - 1))); do
            #     IP=$(docker exec -i my5grantester$j sh -c "ip -4 addr show uetun1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
            #     docker exec my5grantester$j sh -c "iperf -c iperf.free5gc.org --bind $IP -t 60 -i 1 -y C" > my5grantester-iperf-$e-$c-$i-$j.csv &
            # done

            # Open for Open5GS
            for j in $(seq 0 $(($i - 1))); do
                IP=$(docker exec -i my5grantester$j sh -c "ip -4 addr show uetun1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
                docker exec my5grantester$j sh -c "iperf -c iperf --bind $IP -t 60 -i 1 -y C" > my5grantester-iperf-$e-$c-$i-$j.csv &
            done

            echo "Waiting for experiment $i to finish"
            sleep $((80))

            echo "Collecting experiment $i data from influxdb"
            docker exec influxdb sh -c "influx query 'from(bucket:\"database\") |> range(start:-5m)' --raw" > my5grantester-iperf-influxdb-$e-$c-$i.csv

            echo "Clear experiment $i environment"
            bash stop_only.sh
            docker image prune --filter="dangling=true" -f
            docker volume prune -f

            sleep 15
        done
    done
done

echo "Cleaning environment"
sleep $((1*60))
bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/stop_and_clear.sh)
docker image prune -a -f
docker volume prune -f
sleep $((1*60))