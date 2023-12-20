import DataDispay from "@/components/dataDispay";
import DataTable, { DataTableProps } from "@/components/dataTable";
import QuerySelectorCard from "@/components/querySelectorCard";
import { Toaster } from "@/components/ui/toaster";
import React, { useState } from "react";

const Home = () => {
  const [data, setData] = useState<DataTableProps<object> | undefined>();
  const [isLoading, setIsLoading] = useState(false);
  return (
    <>
      <main className="text-center p-10">
        <h1 className="text-2xl font-bold">
          US Building Carbon Intensity and Energy Usage Analyzer
        </h1>
        <div className="flex flex-col gap-10 w-full items-center">
          <h2 className="text-muted-foreground text-sm ">
            Based on the ElA's 2018 survey of Commercial Building Energy
            Consumption
          </h2>

          <QuerySelectorCard setData={setData} setIsLoading={setIsLoading} />

          <DataDispay
            id={data?.id}
            fields={data?.fields || []}
            rowData={data?.rowData || []}
            isLoading={isLoading}
          />
        </div>
      </main>
      <Toaster />
    </>
  );
};

export default Home;
