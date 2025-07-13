import pytest
from unittest.mock import patch, MagicMock

from sqlalchemy.exc import IntegrityError

from app.infrastructure.db.connection_pool import ConnectionPool


@pytest.fixture
def mock_engine_url():
    return 'sqlite:///:memory:'


@pytest.fixture
def pool(mock_engine_url):
    return ConnectionPool(mock_engine_url)


class TestConnectionPool:
    def test_open_session_commits(self, pool):
        # Arrange
        with patch.object(pool, 'session_factory') as mock_factory:
            mock_session = MagicMock()
            mock_factory.return_value = mock_session

            # Act
            with pool.open_session() as session:
                session.execute('SELECT 1')

            # Assert
            mock_session.commit.assert_called_once()
            mock_session.close.assert_called_once()

    def test_open_session_rollback_on_integrity_error(self, pool):
        # Arrange
        with patch.object(pool, 'session_factory') as mock_factory:
            mock_session = MagicMock()
            mock_session.commit.side_effect = IntegrityError('IntegrityError', {}, None)
            mock_factory.return_value = mock_session

            # Act & Assert
            with pytest.raises(IntegrityError):
                with pool.open_session() as session:
                    session.execute('SELECT * FROM fail')

            mock_session.rollback.assert_called_once()
            mock_session.close.assert_called_once()

    def test_open_session_always_closes(self, pool):
        # Arrange
        with patch.object(pool, 'session_factory') as mock_factory:
            mock_session = MagicMock()
            mock_factory.return_value = mock_session

            # Act
            try:
                with pool.open_session():
                    raise Exception('Random failure')
            except Exception:
                pass

            # Assert
            mock_session.close.assert_called_once()
