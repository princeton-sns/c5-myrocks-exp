/******************************************************************************
 *  Copyright 2015 by OLTPBenchmark Project                                   *
 *                                                                            *
 *  Licensed under the Apache License, Version 2.0 (the "License");           *
 *  you may not use this file except in compliance with the License.          *
 *  You may obtain a copy of the License at                                   *
 *                                                                            *
 *    http://www.apache.org/licenses/LICENSE-2.0                              *
 *                                                                            *
 *  Unless required by applicable law or agreed to in writing, software       *
 *  distributed under the License is distributed on an "AS IS" BASIS,         *
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  *
 *  See the License for the specific language governing permissions and       *
 *  limitations under the License.                                            *
 ******************************************************************************/

package com.oltpbenchmark.benchmarks.tpcc.procedures;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Random;

import org.apache.log4j.Logger;

import com.oltpbenchmark.api.SQLStmt;
import com.oltpbenchmark.benchmarks.tpcc.TPCCConstants;
import com.oltpbenchmark.benchmarks.tpcc.TPCCUtil;
import com.oltpbenchmark.benchmarks.tpcc.TPCCWorker;

public class StockLevel extends TPCCProcedure {

    private static final Logger LOG = Logger.getLogger(StockLevel.class);

    // StockLevel Txn
    private CallableStatement storedProc = null;

    public ResultSet run(Connection conn, Random gen,
			 int w_id, int numWarehouses,
			 int terminalDistrictLowerID, int terminalDistrictUpperID,
			 TPCCWorker w) throws SQLException {

        if (storedProc == null) {
            storedProc = conn.prepareCall("{call stock_level(?, ?, ?, ?)}");
        }

	boolean trace = LOG.isTraceEnabled();

	int d_id = TPCCUtil.randomNumber(terminalDistrictLowerID,terminalDistrictUpperID, gen);
	int threshold = TPCCUtil.randomNumber(10, 20, gen);

	storedProc.setInt(1, w_id);
	storedProc.setInt(2, d_id);
	storedProc.setInt(3, threshold);

	storedProc.registerOutParameter(4, Types.INTEGER);
	     
	storedProc.execute();

	int stock_count = (Integer) storedProc.getObject(4, Integer.class);

	if (trace) LOG.trace("stockGetCountStock RESULT=" + stock_count);

	if (trace) {
	    StringBuilder terminalMessage = new StringBuilder();
	    terminalMessage.append("\n+-------------------------- STOCK-LEVEL --------------------------+");
	    terminalMessage.append("\n Warehouse: ");
	    terminalMessage.append(w_id);
	    terminalMessage.append("\n District:  ");
	    terminalMessage.append(d_id);
	    terminalMessage.append("\n\n Stock Level Threshold: ");
	    terminalMessage.append(threshold);
	    terminalMessage.append("\n Low Stock Count:       ");
	    terminalMessage.append(stock_count);
	    terminalMessage.append("\n+-----------------------------------------------------------------+\n\n");
	    LOG.trace(terminalMessage.toString());
	}

	return null;
    }
}
