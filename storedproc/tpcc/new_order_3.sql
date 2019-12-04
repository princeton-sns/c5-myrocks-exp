/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2003 Mark Wong & Open Source Development Lab, Inc.
 * Copyright (C) 2004 Alexey Stroganov & MySQL AB.
 *
 * Based on TPC-C Standard Specification Revision 5.0 Clause 2.8.2.
 */

use fdr;
drop procedure if exists new_order_3;

delimiter |


  CREATE PROCEDURE new_order_3 (in_w_id INT,
	                              in_d_id INT,
	                              in_ol_i_id INT,
	                              in_ol_quantity INT,
	                              in_ol_o_id INT,
	                              in_ol_amount NUMERIC,
	                              in_ol_supply_w_id INT,
	                              in_ol_number INT,
                                in_s_dist VARCHAR(255))

  BEGIN
	  INSERT INTO ORDER_LINE (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id,
	                          ol_supply_w_id, ol_delivery_d, ol_quantity,
                            ol_amount, ol_dist_info)
	  VALUES (in_ol_o_id, in_d_id, in_w_id, in_ol_number, in_ol_i_id,
	          in_ol_supply_w_id, NULL, in_ol_quantity, in_ol_amount,
	          in_s_dist);
  END|
    delimiter ;
