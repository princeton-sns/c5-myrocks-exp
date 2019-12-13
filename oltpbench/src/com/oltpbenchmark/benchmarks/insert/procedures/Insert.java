package com.oltpbenchmark.benchmarks.insert.procedures;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;
import org.apache.log4j.Logger;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Insert extends Procedure {

    private static final Logger LOG = Logger.getLogger(Insert.class);

    // Insert Txn
    private CallableStatement storedProc = null;

    public void run(Connection conn, int key) throws SQLException {
        if (storedProc == null) {
            storedProc = conn.prepareCall("{call insertsp(?, ?)}");
        }

        storedProc.setInt(1, key);
        storedProc.setInt(2, key);

        storedProc.execute();
    }

}
