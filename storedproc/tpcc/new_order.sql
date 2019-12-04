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
drop procedure if exists new_order;

delimiter |

  CREATE PROCEDURE new_order(tmp_w_id INT,
                             tmp_d_id INT,
                             tmp_c_id INT,
                             tmp_o_all_local INT,
                             tmp_o_ol_cnt INT,
                             ol_i_id1 INT,
                             ol_supply_w_id1 INT,
                             ol_quantity1 INT,
                             ol_i_id2 INT,
                             ol_supply_w_id2 INT,
                             ol_quantity2 INT,
                             ol_i_id3 INT,
                             ol_supply_w_id3 INT,
                             ol_quantity3 INT,
                             ol_i_id4 INT,
                             ol_supply_w_id4 INT,
                             ol_quantity4 INT,
                             ol_i_id5 INT,
                             ol_supply_w_id5 INT,
                             ol_quantity5 INT,
                             ol_i_id6 INT,
                             ol_supply_w_id6 INT,
                             ol_quantity6 INT,
                             ol_i_id7 INT,
                             ol_supply_w_id7 INT,
                             ol_quantity7 INT,
                             ol_i_id8 INT,
                             ol_supply_w_id8 INT,
                             ol_quantity8 INT,
                             ol_i_id9 INT,
                             ol_supply_w_id9 INT,
                             ol_quantity9 INT,
                             ol_i_id10 INT,
                             ol_supply_w_id10 INT,
                             ol_quantity10 INT,
                             ol_i_id11 INT,
                             ol_supply_w_id11 INT,
                             ol_quantity11 INT,
                             ol_i_id12 INT,
                             ol_supply_w_id12 INT,
                             ol_quantity12 INT,
                             ol_i_id13 INT,
                             ol_supply_w_id13 INT,
                             ol_quantity13 INT,
                             ol_i_id14 INT,
                             ol_supply_w_id14 INT,
                             ol_quantity14 INT,
                             ol_i_id15 INT,
                             ol_supply_w_id15 INT,
                             ol_quantity15 INT,
                             out rc int)

  BEGIN

    DECLARE out_c_credit VARCHAR(255);
    DECLARE tmp_i_name VARCHAR(255);
    DECLARE tmp_i_data VARCHAR(255);
    DECLARE out_c_last VARCHAR(255);

    DECLARE tmp_ol_supply_w_id INT;
    DECLARE tmp_ol_quantity INT;
    DECLARE out_d_next_o_id INT;
    DECLARE tmp_i_id INT;

    DECLARE tmp_s_dist1 VARCHAR(255);
    DECLARE tmp_s_dist2 VARCHAR(255);
    DECLARE tmp_s_dist3 VARCHAR(255);
    DECLARE tmp_s_dist4 VARCHAR(255);
    DECLARE tmp_s_dist5 VARCHAR(255);
    DECLARE tmp_s_dist6 VARCHAR(255);
    DECLARE tmp_s_dist7 VARCHAR(255);
    DECLARE tmp_s_dist8 VARCHAR(255);
    DECLARE tmp_s_dist9 VARCHAR(255);
    DECLARE tmp_s_dist10 VARCHAR(255);
    DECLARE tmp_s_dist11 VARCHAR(255);
    DECLARE tmp_s_dist12 VARCHAR(255);
    DECLARE tmp_s_dist13 VARCHAR(255);
    DECLARE tmp_s_dist14 VARCHAR(255);
    DECLARE tmp_s_dist15 VARCHAR(255);

    DECLARE out_w_tax REAL;
    DECLARE out_d_tax REAL;
    DECLARE out_c_discount REAL;

    DECLARE tmp_i_price1 REAL;
    DECLARE tmp_i_price2 REAL;
    DECLARE tmp_i_price3 REAL;
    DECLARE tmp_i_price4 REAL;
    DECLARE tmp_i_price5 REAL;
    DECLARE tmp_i_price6 REAL;
    DECLARE tmp_i_price7 REAL;
    DECLARE tmp_i_price8 REAL;
    DECLARE tmp_i_price9 REAL;
    DECLARE tmp_i_price10 REAL;
    DECLARE tmp_i_price11 REAL;
    DECLARE tmp_i_price12 REAL;
    DECLARE tmp_i_price13 REAL;
    DECLARE tmp_i_price14 REAL;
    DECLARE tmp_i_price15 REAL;

    DECLARE tmp_ol_amount REAL;
    DECLARE tmp_total_amount REAL;

    declare exit handler for sqlstate '02000' set rc = 1;

    SET rc=0;

    SELECT w_tax
      INTO out_w_tax
      FROM WAREHOUSE
     WHERE w_id = tmp_w_id;

    SELECT c_discount, c_last, c_credit
      INTO out_c_discount, out_c_last, out_c_credit
      FROM CUSTOMER
     WHERE c_w_id = tmp_w_id
       AND c_d_id = tmp_d_id
       AND c_id = tmp_c_id;

    IF tmp_o_ol_cnt > 0
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price1, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id1;

      IF tmp_i_price1 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id1,
                         ol_quantity1, tmp_s_dist1);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 1
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price2, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id2;

      IF tmp_i_price2 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id2,
                         ol_quantity2, tmp_s_dist2);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 2
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price3, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id3;

      IF tmp_i_price3 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id3,
                         ol_quantity3, tmp_s_dist3);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 3
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price4, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id4;

      IF tmp_i_price4 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id4,
                         ol_quantity4, tmp_s_dist4);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 4
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price5, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id5;

      IF tmp_i_price5 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id5,
                         ol_quantity5, tmp_s_dist5);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 5
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price6, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id6;

      IF tmp_i_price6 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id6,
                         ol_quantity6, tmp_s_dist6);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 6
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price7, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id7;

      IF tmp_i_price7 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id7,
                         ol_quantity7, tmp_s_dist7);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 7
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price8, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id8;

      IF tmp_i_price8 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id8,
                         ol_quantity8, tmp_s_dist8);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 8
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price9, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id9;

      IF tmp_i_price9 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id9,
                         ol_quantity9, tmp_s_dist9);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 9
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price10, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id10;

      IF tmp_i_price10 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id10,
                         ol_quantity10, tmp_s_dist10);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 10
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price11, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id11;

      IF tmp_i_price11 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id11,
                         ol_quantity11, tmp_s_dist11);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 11
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price12, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id12;

      IF tmp_i_price12 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id12,
                         ol_quantity12, tmp_s_dist12);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 12
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price13, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id13;

      IF tmp_i_price13 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id13,
                         ol_quantity13, tmp_s_dist13);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 13
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price14, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id14;

      IF tmp_i_price14 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id14,
                         ol_quantity14, tmp_s_dist14);
        END IF;
      END IF;

    IF tmp_o_ol_cnt > 14
    THEN

      SELECT i_price, i_name, i_data
      INTO tmp_i_price15, tmp_i_name, tmp_i_data
      FROM ITEM
      WHERE i_id = ol_i_id15;

      IF tmp_i_price15 > 0
      THEN
        call new_order_2(tmp_w_id, tmp_d_id, ol_i_id15,
                         ol_quantity15, tmp_s_dist15);
        END IF;
      END IF;

    SELECT d_tax, d_next_o_id
      INTO out_d_tax, out_d_next_o_id
      FROM DISTRICT
     WHERE d_w_id = tmp_w_id
       AND d_id = tmp_d_id FOR UPDATE;

    UPDATE DISTRICT
       SET d_next_o_id = d_next_o_id + 1
     WHERE d_w_id = tmp_w_id
           AND d_id = tmp_d_id;

    INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id)
    VALUES (out_d_next_o_id, tmp_d_id, tmp_w_id);

    INSERT INTO OORDER (o_id, o_d_id, o_w_id, o_c_id, o_entry_d,
	                      o_carrier_id, o_ol_cnt, o_all_local)
    VALUES (out_d_next_o_id, tmp_d_id, tmp_w_id, tmp_c_id,
	          current_timestamp, NULL, tmp_o_ol_cnt, tmp_o_all_local);

    SET tmp_total_amount = 0;

    IF tmp_o_ol_cnt > 0 AND tmp_i_price1 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price1 * ol_quantity1;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id1,
                       ol_quantity1,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id1, 1, tmp_s_dist1);

      SET tmp_total_amount = tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 1 AND tmp_i_price2 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price2 * ol_quantity2;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id2,
                       ol_quantity2,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id2, 2, tmp_s_dist2);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 2 AND tmp_i_price3 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price3 * ol_quantity3;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id3,
                       ol_quantity3,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id3, 3, tmp_s_dist3);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 3 AND tmp_i_price4 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price4 * ol_quantity4;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id4,
                       ol_quantity4,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id4, 4, tmp_s_dist4);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 4 AND tmp_i_price5 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price5 * ol_quantity5;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id5,
                       ol_quantity5,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id5, 5, tmp_s_dist5);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 5 AND tmp_i_price6 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price6 * ol_quantity6;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id6,
                       ol_quantity6,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id6, 6, tmp_s_dist6);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 6 AND tmp_i_price7 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price7 * ol_quantity7;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id7,
                       ol_quantity7,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id7, 7, tmp_s_dist7);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 7 AND tmp_i_price8 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price8 * ol_quantity8;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id8,
                       ol_quantity8,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id8, 8, tmp_s_dist8);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 8 AND tmp_i_price9 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price9 * ol_quantity9;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id9,
                       ol_quantity9,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id9, 9, tmp_s_dist9);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 9 AND tmp_i_price10 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price10 * ol_quantity10;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id10,
                       ol_quantity10,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id10, 10, tmp_s_dist10);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 10 AND tmp_i_price11 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price11 * ol_quantity11;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id11,
                       ol_quantity11,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id11, 11, tmp_s_dist11);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 11 AND tmp_i_price12 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price12 * ol_quantity12;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id12,
                       ol_quantity12,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id12, 12, tmp_s_dist12);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 12 AND tmp_i_price13 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price13 * ol_quantity13;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id13,
                       ol_quantity13,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id13, 13, tmp_s_dist13);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 13 AND tmp_i_price14 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price14 * ol_quantity14;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id14,
                       ol_quantity14,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id14, 14, tmp_s_dist14);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

    IF tmp_o_ol_cnt > 14 AND tmp_i_price15 > 0
    THEN
      SET tmp_ol_amount = tmp_i_price15 * ol_quantity15;
      call new_order_3(tmp_w_id, tmp_d_id, ol_i_id15,
                       ol_quantity15,
  		                 out_d_next_o_id, tmp_ol_amount,
                       ol_supply_w_id15, 15, tmp_s_dist15);

	    SET tmp_total_amount = tmp_total_amount + tmp_ol_amount;
      END IF;

  END|
    delimiter ;
