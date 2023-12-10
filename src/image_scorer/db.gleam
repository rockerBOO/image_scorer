import sqlight

pub fn create_tables(conn) {
  let sql = "create table image_scores (image text, score int);"
  sqlight.exec(sql, conn)
}
