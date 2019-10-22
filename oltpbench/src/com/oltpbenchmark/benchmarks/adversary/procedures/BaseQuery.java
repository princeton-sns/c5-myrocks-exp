package com.oltpbenchmark.benchmarks.adversary.procedures;

import java.util.List;
import java.util.Random;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.apache.commons.lang.RandomStringUtils;
import org.apache.log4j.Logger;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;

public abstract class BaseQuery extends Procedure {

    private static final Logger LOG = Logger.getLogger(BaseQuery.class);

    private static final Random random = new Random();

    public final SQLStmt updateStmt = new SQLStmt("UPDATE HOTKEY SET V = ? WHERE K = ?");

    protected abstract SQLStmt getInsertStmt();

    public void run(Connection conn, int hotKey, List<Integer> keys) throws SQLException {
	PreparedStatement update = this.getPreparedStatement(conn, updateStmt);

	update.setInt(1, random.nextInt());
	update.setInt(2, hotKey);

	SQLStmt insertStmt = getInsertStmt();
	PreparedStatement insert;
	if (insertStmt != null) {
	    insert = this.getPreparedStatement(conn, insertStmt);

	    int i = 0;
	    for (Integer k : keys) {
		insert.setInt(++i, k);
		insert.setInt(++i, k);
		insert.setInt(++i, random.nextInt());
	    }

	    insert.execute();
	}

	update.execute();
    }

}
