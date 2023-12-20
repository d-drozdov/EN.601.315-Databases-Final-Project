import React from "react";
import { Pie } from "react-chartjs-2";
import "chart.js/auto";
import { BarChartProps } from "./visual2";

const Visual26 = <T extends object>({
  fields,
  rowData,
}: BarChartProps<T>) => {
  if (!fields || !rowData) {
    return <p className="text-center">No data to display</p>;
  }

  // Group data by region
  const dataByRegion = rowData.reduce((acc, item) => {
    const region = item[fields[0] as keyof T] as string;
    if (!acc[region]) {
      acc[region] = [];
    }
    acc[region].push(item);
    return acc;
  }, {} as Record<string, T[]>);

  // Create a pie chart for each region
  const pieCharts = Object.entries(dataByRegion).map(([region, data]) => {
    const labels = data.map((item) => item[fields[1] as keyof T]);
    const percentages = data.map((item) =>
      parseFloat(item[fields[3] as keyof T] as unknown as string)
    );

    const chartData = {
      labels: labels,
      datasets: [
        {
          data: percentages,
          backgroundColor: [
            // Add more colors for more fuel types if necessary
            "rgba(255, 99, 132, 0.6)",
            "rgba(54, 162, 235, 0.6)",
            "rgba(255, 206, 86, 0.6)",
            "rgba(75, 192, 192, 0.6)",
            "rgba(153, 102, 255, 0.6)",
            "rgba(255, 159, 64, 0.6)",
          ],
          hoverOffset: 4,
        },
      ],
    };

    const options = {
      responsive: true,
      plugins: {
        legend: {
          position: "bottom",
          labels: {
            boxWidth: 20,
            padding: 20,
            usePointStyle: true,
          },
        },
        tooltip: {
          callbacks: {
            label: function (context: any) {
              let label = context.label || "";
              if (label) {
                label += ": ";
              }
              const value = context.raw;
              label += `${value}%`; // Add the percent sign
              return label;
            },
          },
        },
        title: {
          display: true,
          text: `Fuel Source Usage Percentage in ${region}`,
          font: {
            size: 18,
          },
        },
      },
    };

    return (
      <div key={region} className="w-full md:w-1/2 p-4">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-lg font-semibold text-center mb-4">{`Fuel Source Usage in ${region}`}</h3>
          {/* @ts-ignore */}
          <Pie data={chartData} options={options} />
        </div>
      </div>
    );
  });

  return <div className="flex flex-wrap justify-center">{pieCharts}</div>;
};

export default Visual26;
