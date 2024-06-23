package primitiveHelpers;

typedef UInt64 = #if cpp cpp.UInt64 #elseif hl hl.UI64 #else UInt #end