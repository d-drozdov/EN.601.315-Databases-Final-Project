const Loading = () => {
  return (
    <div className="flex flex-col justify-center items-center h-full">
      <div className="animate-spin rounded-full h-10 w-10 border-b-4 border-accent-foreground mb-4"></div>
      <p className="text-sm font-semibold text-accent-foreground">Loading...</p>
    </div>
  );
};

export default Loading;
