import React from "react";
import Chart from "react-apexcharts";

export default function LiveCharts() {
  const [series, setSeries] = React.useState([
    { name: "Throughput", data: [] },
  ]);

  React.useEffect(() => {
    let mounted = true;
    async function fetchSeries() {
      try {
        const res = await fetch("/api/metrics/engine?span=1h&step=60s");
        const json = await res.json();
        if (!mounted) return;
        setSeries(json.series || []);
      } catch (e) {
        console.error(e);
      }
    }
    fetchSeries();
    const t = setInterval(fetchSeries, 10000);
    return () => {
      mounted = false;
      clearInterval(t);
    };
  }, []);

  const opts = {
    chart: { animations: { enabled: true } },
    xaxis: { type: "datetime" },
  };
  return <Chart options={opts} series={series} type="line" height={320} />;
}
