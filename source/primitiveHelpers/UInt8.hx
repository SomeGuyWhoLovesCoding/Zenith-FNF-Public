package primitiveHelpers;

typedef UInt8 = #if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end