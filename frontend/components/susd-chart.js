import { useState, useEffect } from "react";
import { Line } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  PointElement,
  LineElement,
  LinearScale,
  Title,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";

const backend = "http://localhost:8082";

ChartJS.register(
  CategoryScale,
  Filler,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

export function SusdChart() {
  const [priceaction, getPrice] = useState([]);
  const [timeaction, getTime] = useState([]);
  const [status, colorStatus] = useState("");
  const [liveprice, getLivePrice] = useState("");

  useEffect(() => {
    const updateChart = setInterval(() => {
      getChart();
    }, 2000);
    return () => clearInterval(updateChart);
  }, [liveprice]);

  async function getChart() {
    let token = "Susd";
    const url = backend + "/getchartinfo";
    const config = {
      method: "POST",
      body: JSON.stringify({ token }),
      headers: {
        "content-type": "application/json",
      },
    };
    const response = await fetch(url, config);
    const output = await response.json();
    const pricearray = output.chartprice;
    const timearray = output.charttime;
    let price = [];
    let time = [];
    let i = 0;
    for (i; i < pricearray.length; i++) {
      let pricenum = pricearray[i].toFixed(4);
      price.push(pricenum);
      time.push(timearray[i]);
    }
    price.reverse();
    time.reverse();
    getLivePrice(price[0]);
    let previous = Number(price[1]);
    let newvalue = Number(price[0]);
    if (previous < newvalue) {
      colorStatus("#39ff1450");
    } else if (previous > newvalue) {
      colorStatus("#dd00a980");
    } else colorStatus("#00c0f935");
    getPrice(price);
    getTime(time);
  }

  const data = {
    labels: [
      timeaction[10],
      timeaction[9],
      timeaction[8],
      timeaction[7],
      timeaction[6],
      timeaction[5],
      timeaction[4],
      timeaction[3],
      timeaction[2],
      timeaction[1],
      timeaction[timeaction.length],
    ],
    datasets: [
      {
        lineTension: 0.4,
        label: "stableCoin",
        borderColor: "#ffffff",
        borderWidth: 4,
        backgroundColor: status,
        borderDashOffset: 0.78,
        borderJoinStyle: "round",
        pointBackgroundColor: "black",
        pointBorderWidth: 5,
        pointBorderColor: "white", // Alternate property for point border color
        pointRadius: 5, // Larger point radius for better visibility
        pointHoverBackgroundColor: "rgba(75,192,192,1)",
        pointHoverBorderColor: "black",
        pointHoverBorderWidth: 2, // Thicker border on hover
        data: [
          priceaction[10],
          priceaction[9],
          priceaction[8],
          priceaction[7],
          priceaction[6],
          priceaction[5],
          priceaction[4],
          priceaction[3],
          priceaction[2],
          priceaction[1],
          priceaction[0],
        ],
        fill: true, // Fills the area under the line with the same color as the line
      },
    ],
  };

  const options = {
    plugins: {
      legend: {
        display: false,
      },
    },
    scales: {
      x: {
        grid: {
          display: false,
        },
        ticks: {
          display: true,
          color: "#ffffff",
          font: {
            size: 14,
            family: "SF Pro Display",
          },
        },
      },
      y: {
        type: "linear",
        position: "right",
        beginAtZero: true, // Starts the y-axis from 0
        grid: {
          drawBorder: false,
          display: true, // Display y-axis grid lines
          color: "rgba(255, 255, 255, 0.1)", // Color of grid lines
        },
        ticks: {
          display: true,
          color: "#fff",
          font: {
            size: 14, // Slightly reduced font size
            family: "SF Pro Display",
          },
          callback: function (value) {
            // Custom formatting for tick labels (adjust as needed)
            return value.toFixed(2);
          },
        },
      },
    },
  };

  return (
    <div className="text-white rounded">
      <div
        className="card p-4"
        style={{
          background: "#0a090b", // Change to the desired background color
          borderRadius: "15px",
        }}
      >
        <div className="d-flex align-items-center justify-content-between mb-3">
          <img
            src="gs.png"
            width="80"
            style={{ opacity: "0.78" }}
            alt="Stablecoin Logo"
          />
          <h4
            className="mb-0"
            style={{
              color: "#fff",
              fontFamily: "SF Pro Display",
              fontWeight: "400",
              fontSize: "1.2rem",
            }}
          >
            {liveprice}
          </h4>
        </div>
        <div className="w-100">
          <Line data={data} options={options} />
        </div>
      </div>
    </div>
  );
}
