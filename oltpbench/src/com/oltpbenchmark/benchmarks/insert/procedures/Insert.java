package com.oltpbenchmark.benchmarks.insert.procedures;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;
import org.apache.log4j.Logger;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Insert extends Procedure {

    private static final Logger LOG = Logger.getLogger(Insert.class);

    private final SQLStmt insertStmt = new SQLStmt("INSERT INTO KV (K, V) VALUES (?, ?)");

    public void run(Connection conn, int key) throws SQLException {
        PreparedStatement insert = this.getPreparedStatement(conn, insertStmt);
	insert.setInt(1, key);
	insert.setInt(2, key);
	insert.execute();
    }

}
