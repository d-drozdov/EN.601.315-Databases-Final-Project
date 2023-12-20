import React from "react";
import { Pie } from "react-chartjs-2";
import "chart.js/auto";
import { BarChartProps } from "./visual2";

const visual13 = <T extends object>({ fields, rowData }: BarChartProps<T>) => {
  if (!fields || !rowData) {
    return <p>No data to display</p>;
  }

  // Aggregate data by region
  const dataByRegion = rowData.reduce((acc, item) => {
    const region = item[fields[0] as keyof T] as string;
    const system = item[fields[1] as keyof T] as string;
    const count = parseInt(item[fields[2] as keyof T] as unknown as string);

    if (!acc[region]) {
      acc[region] = { systems: [], counts: [] };
    }

    acc[region].systems.push(system);
    acc[region].counts.push(count);

    return acc;
  }, {} as Record<string, { systems: string[]; counts: number[] }>);

  // Map over each region to create a pie chart
  const pieCharts = Object.entries(dataByRegion).map(
    ([region, { systems, counts }]) => {
      const chartData = {
        labels: systems,
        datasets: [
          {
            data: counts,
            backgroundColor: [
              // Define more colors if you have more categories
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
            },
          },
          title: {
            display: true,
            text: `Water Heating System Distribution in ${region}`,
            font: {
              size: 18,
            },
          },
        },
      };

      return (
        <div key={region} className="m-4 w-full md:w-1/2 lg:w-1/3">
          <h3 className="text-lg font-bold text-center mb-2">{region}</h3>
          {/* @ts-ignore */}
          <Pie data={chartData} options={options} />
        </div>
      );
    }
  );

  return <div className="flex flex-wrap justify-center">{pieCharts}</div>;
};

export default visual13;
