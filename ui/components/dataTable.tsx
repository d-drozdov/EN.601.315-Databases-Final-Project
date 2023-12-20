import { IconChevronDown, IconChevronUp } from "@tabler/icons-react";
import React from "react";
import { Column, useTable, useSortBy, HeaderGroup } from "react-table";

export type DataTableProps<T extends object> = {
  fields: string[] | undefined;
  rowData: T[] | undefined;
  id: string | undefined;
};

const DataTable = <T extends object>({
  fields,
  rowData,
}: DataTableProps<T>) => {
  if (!fields || !rowData) {
    return <p>No data to display</p>;
  }

  const columns: Column<T>[] = React.useMemo(() => {
    return fields.map((field) => ({
      Header: field.charAt(0).toUpperCase() + field.slice(1).replace(/_/g, " "),
      accessor: field as keyof T,
    }));
  }, [fields]);

  const tableInstance = useTable({ columns, data: rowData }, useSortBy);

  return (
    <div className="flex justify-center max-w-full w-full">
      <div className="overflow-x-auto relative shadow-lg sm:rounded-lg max-h-[750px]">
        <table
          {...tableInstance.getTableProps()}
          className="w-full text-sm text-center text-gray-600"
        >
          <thead className="text-xs text-primary-foreground uppercase bg-primary sticky top-0">
            {tableInstance.headerGroups.map((headerGroup) => (
              <tr {...headerGroup.getHeaderGroupProps()}>
                {headerGroup.headers.map((column) => (
                  <th
                    {
                      //@ts-ignore
                      ...column.getHeaderProps(column.getSortByToggleProps)
                    }
                    className="py-3 px-8"
                  >
                    <div className="flex items-center justify-center">
                      <p>{column.render("Header")}</p>

                      {
                        //@ts-ignore
                        column.isSorted ? (
                          //@ts-ignore
                          column.isSortedDesc ? (
                            <IconChevronUp size={15} />
                          ) : (
                            <IconChevronDown size={15} />
                          )
                        ) : (
                          ""
                        )
                      }
                    </div>
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody {...tableInstance.getTableBodyProps()} className="bg-white">
            {tableInstance.rows.map((row) => {
              tableInstance.prepareRow(row);
              return (
                <tr {...row.getRowProps()} className="border-b">
                  {row.cells.map((cell) => (
                    <td
                      {...cell.getCellProps()}
                      className="py-4 px-8 text-center"
                    >
                      {cell.render("Cell")}
                    </td>
                  ))}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default DataTable;
