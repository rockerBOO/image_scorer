import sqlight

pub fn create_tables(conn) {
  let sql = "create table if not exists image_scores (image text, score int);"
  sqlight.exec(sql, conn)
}
