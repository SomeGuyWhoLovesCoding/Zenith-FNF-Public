package zenith;

// Don't make the code messier
typedef Float32 = #if (cpp || hl) Single #else Float #end ;