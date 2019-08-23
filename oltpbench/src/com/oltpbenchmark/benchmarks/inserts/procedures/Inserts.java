package com.oltpbenchmark.benchmarks.inserts.procedures;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;
import org.apache.log4j.Logger;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Inserts extends Procedure {
    private static final Logger LOG = Logger.getLogger(Inserts.class);

    private final SQLStmt insertStmt = new SQLStmt("INSERT INTO KV (ID, VAL) VALUES (?, ?)");

    public void run(Connection conn, int key) throws SQLException {
        PreparedStatement insert = this.getPreparedStatement(conn, insertStmt);

        try {
            insert.setInt(1, key);
            insert.setInt(2, key);
            insert.execute();
        } catch (Exception ex) {
            if (LOG.isDebugEnabled()) {
                LOG.debug("Exception for Inserts query. This may be expected!", ex);
            }
        }
    }

}
