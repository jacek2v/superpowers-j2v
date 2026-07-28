import feedmix


def test_add_article_returns_row_id():
    conn = feedmix.connect(":memory:")
    assert feedmix.add_article(conn, "Hello", "World") == 1


def test_list_articles_in_insertion_order():
    conn = feedmix.connect(":memory:")
    feedmix.add_article(conn, "First", "a")
    feedmix.add_article(conn, "Second", "b")
    assert feedmix.list_articles(conn) == [(1, "First"), (2, "Second")]
