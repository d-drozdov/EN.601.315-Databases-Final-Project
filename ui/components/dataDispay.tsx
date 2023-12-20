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
type Props = {
  isLoading: boolean;
};
const DataDispay = <T extends object>({
  id,
  fields,
  rowData,
  isLoading,
}: DataTableProps<T> & Props) => {
  console.log("fields dataDisplay", fields);
  console.log("rowData dataDisplay", rowData);

  return (
    <>
      <Card className="w-11/12">
        <CardHeader>
          <CardTitle>Data Visualizer</CardTitle>
          <div className="flex justify-center">
            <CardDescription className="w-3/4">
              This area will display the data you have selected and any
              associated visualizations. The data tables are sortable by
              clicking on the column headers.
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent className="flex justify-center">
          {isLoading ? (
            <Loading />
          ) : (
            <div className="flex flex-col gap-10">
              <div className="w-full my-4">
                <Visual2 fields={fields} rowData={rowData} />
              </div>
              <DataTable fields={fields} rowData={rowData} id={id} />
            </div>
          )}
        </CardContent>
      </Card>
    </>
  );
};

export default DataDispay;
