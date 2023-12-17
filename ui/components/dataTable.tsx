import { IconChevronDown, IconChevronUp } from "@tabler/icons-react";
import React from "react";
import { Column, useTable, useSortBy } from "react-table";

type Props<T extends object> = {
  fields: string[];
  rowData: T[];
};

const DataTable = <T extends object>({ fields, rowData }: Props<T>) => {
  const columns: Column<T>[] = React.useMemo(() => {
    return fields.map((field) => ({
      Header: field.charAt(0).toUpperCase() + field.slice(1).replace(/_/g, " "),
      accessor: field as keyof T,
    }));
  }, [fields]);

  const tableInstance = useTable({ columns, data: rowData }, useSortBy);

  return (
    <div className="flex justify-center">
      <div className="overflow-x-auto relative shadow-lg sm:rounded-lg max-h-[650px]">
        <table
          {...tableInstance.getTableProps()}
          className="w-full text-sm text-center text-gray-600"
        >
          <thead className="text-xs text-gray-700 uppercase bg-gray-400 sticky top-0">
            {tableInstance.headerGroups.map((headerGroup) => (
              <tr
                {...headerGroup.getHeaderGroupProps()}
                className="group relative"
              >
                {headerGroup.headers.map((column) => (
                  <th
                    {...column.getHeaderProps(column.getSortByToggleProps())}
                    className="py-3 px-6"
                  >
                    <div className="flex items-center justify-center">
                      <span>{column.render("Header")}</span>
                      {column.isSorted ? (
                        column.isSortedDesc ? (
                          <IconChevronUp size={15} />
                        ) : (
                          <IconChevronDown size={15} />
                        )
                      ) : (
                        ""
                      )}
                    </div>
                  </th>
                ))}
                <span className="group-hover:opacity-100 transition-opacity bg-gray-800 px-1 text-xs text-gray-100 rounded-md absolute left-1/2 -translate-x-1/2 translate-y-full opacity-0 m-4 mx-auto lowercase">
                  Click on column header to sort
                </span>
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
                      className="py-4 px-6 text-center"
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
