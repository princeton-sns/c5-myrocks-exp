package com.oltpbenchmark.benchmarks.insert.procedures;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;
import org.apache.log4j.Logger;

import java.util.Random;

import java.sql.Types;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class PointRead extends InsertProcedure {

    private static final Logger LOG = Logger.getLogger(PointRead.class);

    private static final Random RANDOM = new Random();

    // PointRead Txn
    private CallableStatement storedProc = null;

    public void run(Connection conn, int key) throws SQLException {
        if (storedProc == null) {
            storedProc = conn.prepareCall("{call pointread(?, ?)}");
        }

        key = RANDOM.nextInt();
        storedProc.setInt(1, key);
        storedProc.registerOutParameter(2, Types.INTEGER);

        storedProc.execute();

        int v = (Integer) storedProc.getObject(2, Integer.class);
    }

}
