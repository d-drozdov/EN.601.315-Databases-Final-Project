const Loading = () => {
  return (
    <div className="flex flex-col justify-center items-center h-full">
      <div className="animate-spin rounded-full h-2 w-2 border-b-4 border-accent mb-4"></div>
      <p className="text-sm font-semibold text-accent">Loading...</p>
    </div>
  );
};

export default Loading;
