import { Suspense } from "react";
import DataTable, { DataTableProps } from "./dataTable";

import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
} from "./ui/card";
import Loading from "./loading";
import React from "react";
import Visual2 from "./visuals/visual2";
import Visual56 from "./visuals/visual5_6";
import Visual9 from "./visuals/visual9";
import Visual13 from "./visuals/visual13";
import Visual26 from "./visuals/visual26";
type Props = {
  isLoading: boolean;
};
const DataDispay = <T extends object>({
  id,
  fields,
  rowData,
  isLoading,
}: DataTableProps<T> & Props) => {
  let visual = <></>;
  console.log("id", id);
  switch (id?.toString()) {
    case "2":
      visual = <Visual2 fields={fields} rowData={rowData} />;
      break;
    case "5":
      visual = (
        <Visual56
          fields={fields}
          rowData={rowData}
          title={
            "Average Consumption Comparison of Electricity Based on Time Period"
          }
        />
      );
      break;
    case "6":
      visual = (
        <Visual56
          fields={fields}
          rowData={rowData}
          title={
            "Average Consumption Comparison of Electricity Based on Building Usage"
          }
        />
      );
      break;
    case "9":
      visual = <Visual9 fields={fields} rowData={rowData} />;
      break;
    case "13":
      visual = <Visual13 fields={fields} rowData={rowData} />;
      break;
    case "26":
      visual = <Visual26 fields={fields} rowData={rowData} />;
      break;
    default:
      visual = <> </>;
      break;
  }

  return (
    <>
      <Card className="w-11/12">
        <CardHeader>
          <CardTitle>Data Visualizer</CardTitle>
          <div className="flex justify-center">
            <CardDescription className="w-3/4">
              This area will display the data you have selected and any
              associated visualizations. The data tables are sortable by
              clicking on the column headers. Additionally, you can hover over
              charts to see more information.
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent className="flex justify-center">
          {isLoading ? (
            <Loading />
          ) : (
            <div className="flex flex-col">
              <div className="w-full my-4">{visual}</div>
              <DataTable fields={fields} rowData={rowData} id={id} />
            </div>
          )}
        </CardContent>
      </Card>
    </>
  );
};

export default DataDispay;
