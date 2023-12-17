import DataTable from '@/components/dataTable';
import React, { useState, useTransition } from 'react';

const Home = () =>{
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState<any>(null);
  const [isPending, startTransition] = useTransition();

  const fetchData = async () => {
    startTransition(() => {
      setData(null);
      setError(null);
    });

    try {
      const response = await fetch('/api/test');
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      const result = await response.json();
      startTransition(() => {
        setData(result);
      });
    } catch (err) {
      console.error(err);
      startTransition(() => {
        setError(err);
      });
    }
  };

  return (
    <div>
      {isPending && <p>Loading...</p>}
      {error && <p>There was an error! Please check the console log</p>}
      {data && <div><DataTable fields={data.fields} rowData={data.rows}/></div>}
      <div className="p-10"></div>
      {data && <div><DataTable fields={data.fields} rowData={data.rows}/></div>}
      <button onClick={fetchData}>Load Data</button>
    </div>
  );
}



export default Home;