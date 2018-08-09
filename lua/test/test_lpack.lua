local l = require"lpack"

bpack=l.pack
bunpack=l.unpack

function hex(s)
 s=string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
 return s
end

a=bpack("sAb8", "test pack", "\027Lua",5*16+1,0,1,4,4,4,0,8)
print(hex(a),string.len(a))

f=string.dump(hex)
b=string.sub(f, 1, string.len(a)) -- ?
print(a==b, string.len(a), string.len(b))
print(bunpack(a,"sbA3b8"))
-- print(bunpack(b,"sbA3b8"))

i=314159265 f="<I>I=I"
a=bpack(f,i,i,i)
print(hex(a))
print(bunpack(a,f))

i=3.14159265 f="<d>d=d"
a=bpack(f,i,i,i)
print(hex(a))
print(bunpack(a,f))
