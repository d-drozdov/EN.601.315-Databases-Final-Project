import React from "react";
import { Bar } from "react-chartjs-2";
import "chart.js/auto";

// Define the prop type for the BarChartComponent
type BarChartProps<T extends object> = {
  fields: string[] | undefined;
  rowData: T[] | undefined;
};

const BarChartComponent = <T extends object>({
  fields,
  rowData,
}: BarChartProps<T>) => {
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
  const naturalGasData = rowData.map((item) =>
    parseFloat(
      (item[fields[2] as keyof T] as unknown as string).replace(/,/g, "")
    )
  );

  console.log("e", naturalGasData);
  const chartData = {
    labels,
    datasets: [
      {
        label: "Avg Electricity Consumption (in thous BTU)",
        data: electricityData,
        backgroundColor: "rgba(53, 162, 235, 0.5)",
      },
      {
        label: "Avg Natural Gas Consumption (in thous BTU)",
        data: naturalGasData,
        backgroundColor: "rgba(255, 99, 132, 0.5)",
      },
    ],
  };

  const options = {
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          // Include a dollar sign in the ticks and format numbers with commas
          callback: function (value, _, _1) {
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
        text: "Average Consumption Comparison of Electricity and Natural Gas",
        font: {
          size: 24,
          weight: "bold",
        },
      },
    },
  };

  return (
    <div>
      <Bar data={chartData} options={options} />
    </div>
  );
};

export default BarChartComponent;
