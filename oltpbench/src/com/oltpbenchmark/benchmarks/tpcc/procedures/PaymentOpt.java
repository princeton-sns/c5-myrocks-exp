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
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.util.ArrayList;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import org.apache.log4j.Logger;

import com.oltpbenchmark.api.SQLStmt;
import com.oltpbenchmark.benchmarks.tpcc.TPCCConstants;
import com.oltpbenchmark.benchmarks.tpcc.TPCCUtil;
import com.oltpbenchmark.benchmarks.tpcc.TPCCWorker;
import com.oltpbenchmark.benchmarks.tpcc.TPCCConfig;
import com.oltpbenchmark.benchmarks.tpcc.pojo.Customer;

public class PaymentOpt extends TPCCProcedure {

    private static final Logger LOG = Logger.getLogger(PaymentOpt.class);

    private static final Lock lock = new ReentrantLock();

    private static AtomicInteger hID = null;

    // PaymentOpt Txn
    private CallableStatement storedProc = null;

    public ResultSet run(Connection conn, Random gen,
                         int w_id, int numWarehouses,
                         int terminalDistrictLowerID, int terminalDistrictUpperID, TPCCWorker w) throws SQLException {
        if (storedProc == null) {
            storedProc = conn.prepareCall("{call paymentopt(?, ?, ?, ?, ?, ?, ?, ?)}");
        }

        lock.lock();
        if (hID == null) {
            hID = new AtomicInteger(numWarehouses * TPCCConfig.configDistPerWhse * TPCCConfig.configCustPerDist);
        }
        lock.unlock();

        int districtID = TPCCUtil.randomNumber(terminalDistrictLowerID, terminalDistrictUpperID, gen);
        int customerID = TPCCUtil.getCustomerID(gen);

        int x = TPCCUtil.randomNumber(1, 100, gen);
        int customerDistrictID;
        int customerWarehouseID;
        if (x <= 85) {
            customerDistrictID = districtID;
            customerWarehouseID = w_id;
        } else {
            customerDistrictID = TPCCUtil.randomNumber(1, TPCCConfig.configDistPerWhse, gen);
            do {
                customerWarehouseID = TPCCUtil.randomNumber(1, numWarehouses, gen);
            } while (customerWarehouseID == w_id && numWarehouses > 1);
        }

        long y = TPCCUtil.randomNumber(1, 100, gen);
        boolean customerByName;
        String customerLastName = null;
        customerID = 0;
        if (y <= 60) {
            // 60% lookups by last name
            customerByName = true;
            customerLastName = TPCCUtil.getNonUniformRandomLastNameForRun(gen);
        } else {
            // 40% lookups by customer ID
            customerByName = false;
            customerID = TPCCUtil.getCustomerID(gen);
	}

        float paymentAmount = (float) (TPCCUtil.randomNumber(100, 500000, gen) / 100.0);

        storedProc.setInt(1, hID.incrementAndGet());
        storedProc.setInt(2, w_id);
        storedProc.setInt(3, districtID);
        storedProc.setInt(4, customerID);
        storedProc.setInt(5, customerWarehouseID);
        storedProc.setInt(6, customerDistrictID);
        storedProc.setString(7, customerLastName);
        storedProc.setFloat(8, paymentAmount);

        storedProc.execute();

        return null;
    }
}
