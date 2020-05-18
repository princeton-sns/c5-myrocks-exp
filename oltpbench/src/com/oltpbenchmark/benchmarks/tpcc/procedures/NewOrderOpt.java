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
import java.util.Arrays;

import org.apache.log4j.Logger;

import com.oltpbenchmark.api.SQLStmt;
import com.oltpbenchmark.benchmarks.tpcc.TPCCConstants;
import com.oltpbenchmark.benchmarks.tpcc.TPCCUtil;
import com.oltpbenchmark.benchmarks.tpcc.TPCCWorker;
import com.oltpbenchmark.benchmarks.tpcc.TPCCConfig;

public class NewOrderOpt extends TPCCProcedure {

    private static final Logger LOG = Logger.getLogger(NewOrder.class);

    // NewOrder Txn
    private CallableStatement storedProc = null;

    public ResultSet run(Connection conn, Random gen,
                         int w_id, int numWarehouses,
                         int terminalDistrictLowerID, int terminalDistrictUpperID,
                         TPCCWorker w) throws SQLException {

        if (storedProc == null) {
            storedProc = conn.prepareCall("{call new_orderopt(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}");
        }

        int d_id = TPCCUtil.randomNumber(terminalDistrictLowerID,terminalDistrictUpperID, gen);
        int c_id = TPCCUtil.getCustomerID(gen);

        int o_ol_cnt = (int) TPCCUtil.randomNumber(5, 15, gen);
        int[] itemIDs = new int[o_ol_cnt];
        int[] supplierWarehouseIDs = new int[o_ol_cnt];
        int[] orderQuantities = new int[o_ol_cnt];
        int o_all_local = 1;
        for (int i = 0; i < o_ol_cnt; i++) {
            itemIDs[i] = TPCCUtil.getItemID(gen);
            if (TPCCUtil.randomNumber(1, 100, gen) > 1) {
                supplierWarehouseIDs[i] = w_id;
            } else {
                do {
                    supplierWarehouseIDs[i] = TPCCUtil.randomNumber(1,
                                                                    numWarehouses, gen);
                } while (supplierWarehouseIDs[i] == w_id
                         && numWarehouses > 1);
                o_all_local = 0;
            }
            orderQuantities[i] = TPCCUtil.randomNumber(1, 10, gen);
        }
        Arrays.sort(itemIDs);

        // we need to cause 1% of the new orders to be rolled back.
        if (TPCCUtil.randomNumber(1, 100, gen) == 1)
            itemIDs[o_ol_cnt - 1] = TPCCConfig.INVALID_ITEM_ID;


        storedProc.setInt(1, w_id);
        storedProc.setInt(2, d_id);
        storedProc.setInt(3, c_id);
        storedProc.setInt(4, o_all_local);
        storedProc.setInt(5, o_ol_cnt);

        int j = 5;
        for (int i = 0; i < 15; i++) {
            if (i < itemIDs.length) {
                storedProc.setInt(++j, itemIDs[i]);
                storedProc.setInt(++j, supplierWarehouseIDs[i]);
                storedProc.setInt(++j, orderQuantities[i]);
            } else {
                storedProc.setInt(++j, -1);
                storedProc.setInt(++j, -1);
                storedProc.setInt(++j, -1);
            }

        }

        storedProc.registerOutParameter(51, Types.INTEGER);

        storedProc.execute();

        int rc = (Integer)storedProc.getObject(51, Integer.class);

        if (rc != 0) {
            throw new UserAbortException("Error while executing new_order.");
        }

        return null;
    }
}
