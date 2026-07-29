import notekeep


def test_add_note_returns_row_id():
    conn = notekeep.connect(":memory:")
    assert notekeep.add_note(conn, "Hello", "World") == 1


def test_edit_note_updates_body():
    conn = notekeep.connect(":memory:")
    note_id = notekeep.add_note(conn, "Title", "old body")
    notekeep.edit_note(conn, note_id, "new body")
    row = conn.execute("SELECT body FROM notes WHERE id = ?", (note_id,)).fetchone()
    assert row[0] == "new body"


def test_list_notes_in_insertion_order():
    conn = notekeep.connect(":memory:")
    notekeep.add_note(conn, "First", "a")
    notekeep.add_note(conn, "Second", "b")
    assert notekeep.list_notes(conn) == [(1, "First"), (2, "Second")]
