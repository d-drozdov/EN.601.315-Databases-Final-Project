import { Bar } from "react-chartjs-2";
import { BarChartProps } from "./visual2";
import "chart.js/auto";

const visual5_6 = <T extends object>({
  fields,
  rowData,
  title,
}: BarChartProps<T> & { title: string }) => {
  if (!fields || !rowData || fields.length < 1 || rowData.length < 1) {
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
    labels,
    datasets: [
      {
        label: "Avg Electricity Consumption (in thous BTU)",
        data: electricityData,
        backgroundColor: "rgba(53, 162, 235, 0.5)",
      },
    ],
  };

  const options = {
    indexAxis: "y",
    scales: {
      x: {
        beginAtZero: true,
        ticks: {
          // Include a dollar sign in the ticks and format numbers with commas
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
        text: title,
        font: {
          size: 25,
          weight: "bold",
        },
      },
    },
  };
  console.log("chartData", chartData);
  //@ts-ignore
  return <Bar data={chartData} options={options} />;
};
export default visual5_6;
