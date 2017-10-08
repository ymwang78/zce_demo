// zdbpgsql.cpp : Defines the entry point for the console application.
//

#include <zce/zdb_rdb.h>
#include <time.h>

const char* _test_drop_sql = "DROP TABLE tbtest;";

const char* _test_create_sql = "CREATE TABLE tbtest ("\
"intv0 BIGINT,"\
"intv1 INTEGER,"\
"tstz timestamp with time zone,"\
"strv0 TEXT"\
");";

const char* _test_create_index_sql =
"CREATE UNIQUE INDEX idx1_tbtest ON tbtest (intv0);";

const char* _test_insert_sql = "INSERT INTO tbtest(intv0,intv1,tstz,strv0) values(?,?,?,?)";

const char* _test_queryall_sql = "SELECT intv0,intv1,tstz,strv0 from tbtest";

const char* _test_query_sql = "SELECT intv0,intv1,tstz,strv0 from tbtest where intv0=?";

const char* _test_query2_sql = "SELECT friend_list from friend_grouplist";

struct _tbltest_t {
    zce_int64 intv0;
    unsigned intv1;
    timespec_t tstz;
    std::string strv0;
};

struct _tbltest2_t {
    zce_int64 intv0;
    unsigned intv1;
    timespec_t tstz;
    std::string strv0;
    std::string strv1;
};

zdb_stmt& operator<<(zdb_stmt& stmt, const _tbltest_t& v) {
    stmt << v.intv0 << v.intv1 << v.tstz << v.strv0;
    return stmt;
}

zdb_stmt& operator>>(zdb_stmt& stmt, _tbltest_t& v) {
    stmt >> v.intv0 >> v.intv1 >> v.tstz >> v.strv0;
    return stmt;
}

zdb_stmt& operator >> (zdb_stmt& stmt, _tbltest2_t& v) {
    stmt >> v.intv0 >> v.intv1 >> v.tstz >> v.strv0 >> v.strv1;
    return stmt;
}

static void __zdb_rdb_test_conn(const zce_smartptr<zdb_database>& db_ptr) {

    auto conn_ptr = db_ptr->get_connection();
    ZCE_ASSERT(conn_ptr != 0);

    int rc = conn_ptr->execute(_test_drop_sql, zdb_stmt::_none, zdb_stmt::_none);
    ZCE_ASSERT_TEXT(rc >= 0, "drop failed");

    rc = conn_ptr->execute(_test_create_sql, zdb_stmt::_none, zdb_stmt::_none);
    ZCE_ASSERT_TEXT(rc >= 0, "create failed");

    rc = conn_ptr->execute(_test_create_index_sql, zdb_stmt::_none, zdb_stmt::_none);
    ZCE_ASSERT_TEXT(rc >= 0, "create failed");

    time_t now = (int)time(0);

    unsigned begin_tick = (unsigned)zce_tick();
    for (unsigned i = 0; i < 10; ++i) {
        _tbltest_t v{ (zce_int64)(now * 1000 + i), i, timespec_t{time(NULL), 0}, "str0" };
        rc = conn_ptr->execute(_test_insert_sql, zdb_stmt::_none, v);
        ZCE_ASSERT_TEXT(rc >= 0, "insert failed");
    }
    ZCE_DEBUG((ZLOG_DEBUG, "tick %d", (unsigned)zce_tick() - begin_tick));

    {
        std::vector<std::string> vec_str;
        rc = conn_ptr->execute(_test_query2_sql, vec_str, now);
        ZCE_ASSERT_TEXT(rc < 0, "select bykey should failed");
    }

    {
        std::vector<_tbltest_t> vec_str;
        rc = conn_ptr->execute(_test_queryall_sql, vec_str, zdb_stmt::_none);
        ZCE_ASSERT_TEXT(rc >= 0, "select all failed");
    }

    {
        std::vector<_tbltest2_t> vec_str;
        rc = conn_ptr->execute(_test_query_sql, vec_str, now);
        ZCE_ASSERT_TEXT(rc < 0, "select bykey should failed");
    }

    {
        std::vector<_tbltest_t> vec_str;
        rc = conn_ptr->execute(_test_query_sql, vec_str, now);
        ZCE_ASSERT_TEXT(rc >= 0, "select bykey failed");
    }

    {
        std::vector<zdb_stmt::body<int, int> > vec_int;
        rc = conn_ptr->execute(_test_query_sql, vec_int, now);
        ZCE_ASSERT_TEXT(rc >= 0, "select bykey failed");
    }
}

void __zdb_rdb_test_sqlite()
{
    zce_smartptr<zdb_database> db_ptr(new zdb_database(zdb_database::ERV_DATABASE_SQLITE, "test2.db?dbkey=testpasswd;PRAGMA synchronous=NORMAL;PRAGMA journal_mode=WAL"));
    //zce_smartptr<zdb_database> db_ptr(new zdb_database(zdb_database::ERV_DATABASE_SQLITE, "test1.db?PRAGMA synchronous=NORMAL;PRAGMA journal_mode=WAL"));

    ///* user:passwd@host:port/dbname */
    //zce_smartptr<zdb_database> db_ptr(new zdb_database(zdb_database::ERV_DATABASE_MYSQL, "zdtest:testpasswd@127.0.0.1:3306/zdtest"));

    __zdb_rdb_test_conn(db_ptr);
}

void __zdb_rdb_test_pgsql()
{
    ///* user:passwd@host:port/dbname */
    zce_smartptr<zdb_database> db_ptr(new zdb_database(zdb_database::ERV_DATABASE_PGSQL, "zhidu:testpasswd@10.162.103.217:5432/test"));
    __zdb_rdb_test_conn(db_ptr);
}



