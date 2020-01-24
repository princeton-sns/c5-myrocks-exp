package com.oltpbenchmark.benchmarks.insert.procedures;

import java.util.List;
import java.util.Random;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.CallableStatement;

import org.apache.commons.lang.RandomStringUtils;
import org.apache.log4j.Logger;

import com.oltpbenchmark.api.Procedure;
import com.oltpbenchmark.api.SQLStmt;

public abstract class InsertProcedure extends Procedure {

    public abstract void run(Connection conn, int key) throws SQLException;

}
