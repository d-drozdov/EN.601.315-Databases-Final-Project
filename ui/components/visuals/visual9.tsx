import React from "react";
import { Bar } from "react-chartjs-2";
import "chart.js/auto";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";

// Register the components with ChartJS
ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);
import { BarChartProps } from "./visual2";

const visual9 = <T extends object>({ fields, rowData }: BarChartProps<T>) => {
  if (!fields || !rowData) {
    return <p>No data to display</p>;
  }

  const labels = rowData.map((item) =>
    (item[fields[0] as keyof T] as unknown as string).replace(/,/g, "")
  );

  const electricityData = rowData.map((item) =>
    parseFloat(
      (item[fields[1] as keyof T] as unknown as string).replace(/,/g, "")
    )
  );

  const chartData = {
    labels: labels,
    datasets: [
      {
        label: "Avg Electricity Consumption (in thous BTU)",
        data: electricityData,
        backgroundColor: ["rgba(255, 206, 86, 0.5)","rgba(54, 162, 235, 0.5)"],
      },
    ],
  };

  const options = {
    indexAxis: "y",
    scales: {
      x: {
        beginAtZero: true,
        title: {
          display: true,
          text: "Average Electricity Consumption (in thous BTU)",
        },
        ticks: {
          callback: function (value: any) {
            return new Intl.NumberFormat().format(value);
          },
        },
      },
    },
    plugins: {
      legend: {
        position: "top",
      },
      title: {
        display: true,
        text: "Daylight vs No Daylight - Electricity Consumption",
        font: {
          size: 25,
          weight: "bold",
        },
      },
    },
  };
  //@ts-ignore
  return <Bar data={chartData} options={options} />;
};

export default visual9;
