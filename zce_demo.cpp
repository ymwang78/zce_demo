#include <stdio.h>
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "Psapi.lib")
#pragma comment(lib, "Shlwapi.lib")
#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "Userenv.lib")

#pragma comment(lib, "libpq.lib")
#pragma comment(lib, "libpgtypes.lib")

#pragma comment(lib, "libzce.lib")

extern void __zdb_rdb_test_pgsql();

int main()
{
    __zdb_rdb_test_pgsql();
    getchar();
    return 0;
}
