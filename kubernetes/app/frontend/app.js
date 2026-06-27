// Конфигурация
// Используем относительный путь или текущий хост для API
const API_URL = window.location.hostname === 'localhost' ? 'http://localhost:3000' : `http://${window.location.hostname}:3000`;

// DOM элементы
const offerForm = document.getElementById('offerForm');
const offersContainer = document.getElementById('offersContainer');

// Загрузка и отображение офферов
async function loadOffers() {
    try {
        offersContainer.innerHTML = '<p class="loading">Загрузка офферов...</p>';

        const response = await fetch(`${API_URL}/api/offers`);

        if (!response.ok) {
            throw new Error('Не удалось загрузить офферы');
        }

        const offers = await response.json();

        if (offers.length === 0) {
            offersContainer.innerHTML = '<p class="loading">Пока нет офферов. Добавьте первый!</p>';
            return;
        }

        displayOffers(offers);
    } catch (error) {
        console.error('Ошибка загрузки офферов:', error);
        offersContainer.innerHTML = `
            <div class="error">
                <strong>Ошибка:</strong> Не удалось подключиться к серверу.
                Убедитесь, что backend запущен на ${API_URL}
            </div>
        `;
    }
}

// Отображение офферов в DOM
function displayOffers(offers) {
    offersContainer.innerHTML = offers.map(offer => `
        <div class="offer-card">
            <h3>${escapeHtml(offer.title)}</h3>
            <div class="offer-company">${escapeHtml(offer.company)}</div>
            <div class="offer-price">${parseFloat(offer.price).toLocaleString('ru-RU')} ₽</div>
            <div class="offer-description">${escapeHtml(offer.description)}</div>
            <div class="offer-date">Создано: ${new Date(offer.created_at).toLocaleDateString('ru-RU')}</div>
            <button class="btn btn-danger" onclick="deleteOffer(${offer.id})">Удалить</button>
        </div>
    `).join('');
}

// Добавление нового оффера
offerForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const title = document.getElementById('title').value;
    const company = document.getElementById('company').value;
    const price = document.getElementById('price').value;
    const description = document.getElementById('description').value;

    try {
        const response = await fetch(`${API_URL}/api/offers`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ title, company, price, description })
        });

        if (!response.ok) {
            throw new Error('Не удалось создать оффер');
        }

        // Сброс формы
        offerForm.reset();

        // Показать сообщение об успехе
        showMessage('Оффер успешно добавлен!', 'success');

        // Перезагрузить офферы
        loadOffers();
    } catch (error) {
        console.error('Ошибка добавления оффера:', error);
        showMessage('Не удалось добавить оффер. Попробуйте еще раз.', 'error');
    }
});

// Удаление оффера
async function deleteOffer(id) {
    if (!confirm('Вы уверены, что хотите удалить этот оффер?')) {
        return;
    }

    try {
        const response = await fetch(`${API_URL}/api/offers/${id}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            throw new Error('Не удалось удалить оффер');
        }

        showMessage('Оффер успешно удален!', 'success');
        loadOffers();
    } catch (error) {
        console.error('Ошибка удаления оффера:', error);
        showMessage('Не удалось удалить оффер. Попробуйте еще раз.', 'error');
    }
}

// Показать сообщение
function showMessage(message, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = type;
    messageDiv.textContent = message;

    const container = document.querySelector('.container');
    container.insertBefore(messageDiv, container.firstChild);

    setTimeout(() => {
        messageDiv.remove();
    }, 3000);
}

// Экранирование HTML для предотвращения XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Загрузка офферов при загрузке страницы
loadOffers();
