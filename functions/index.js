const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const cors = require('cors')({ origin: true });
const axios = require('axios');

admin.initializeApp();

// Конфигурация email (настройте через Firebase Config)
// firebase functions:config:set email.user="your-email@gmail.com" email.pass="your-app-password"
const getEmailConfig = () => {
  const config = functions.config();
  return {
    user: config.email?.user || process.env.EMAIL_USER,
    pass: config.email?.password || config.email?.pass || process.env.EMAIL_PASS,
    from: config.email?.from || config.email?.user,
    fromName: config.email?.from_name || 'Anama',
  };
};

// Создание транспорта для отправки email
const createTransporter = () => {
  const { user, pass } = getEmailConfig();
  
  if (!user || !pass) {
    console.error('❌ Email конфигурация не настроена!');
    console.error('Выполните: firebase functions:config:set email.user="your-email@gmail.com" email.pass="your-app-password"');
    return null;
  }

  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: user,
      pass: pass, // Используйте App Password от Google
    },
  });
};

// HTML шаблон письма
const getEmailTemplate = (otp, language = 'ru') => {
  const templates = {
    ru: {
      subject: 'Код подтверждения Anama',
      body: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #FDF8F9;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <tr>
      <td style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 16px 16px 0 0; padding: 40px 20px; text-align: center;">
        <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">🕊️ Anama</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Эмоциональная безопасность</p>
      </td>
    </tr>
    <tr>
      <td style="background-color: white; padding: 40px 30px; border-radius: 0 0 16px 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h2 style="color: #5D2A3B; margin: 0 0 20px 0; font-size: 24px;">Подтверждение родительского согласия</h2>
        
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
          Ваш ребенок зарегистрировался в приложении Anama. Для подтверждения родительского согласия введите код ниже:
        </p>
        
        <div style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">
          <p style="color: white; font-size: 14px; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">Ваш код подтверждения</p>
          <p style="color: white; font-size: 42px; font-weight: bold; margin: 0; letter-spacing: 8px; font-family: monospace;">${otp}</p>
        </div>
        
        <div style="background-color: #FFF5F7; border-left: 4px solid #E8A5B3; padding: 15px; margin: 20px 0; border-radius: 0 8px 8px 0;">
          <p style="color: #5D2A3B; font-size: 14px; margin: 0;">
            <strong>⚠️ Важно:</strong> Код действителен 10 минут. Никому не сообщайте этот код.
          </p>
        </div>
        
        <p style="color: #999; font-size: 14px; line-height: 1.6;">
          Если вы не запрашивали этот код, просто проигнорируйте это письмо.
        </p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
          © ${new Date().getFullYear()} Anama. Эмоциональная безопасность вашего ребенка.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
      `,
    },
    kk: {
      subject: 'Anama растау коды',
      body: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #FDF8F9;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <tr>
      <td style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 16px 16px 0 0; padding: 40px 20px; text-align: center;">
        <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">🕊️ Anama</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Эмоциялық қауіпсіздік</p>
      </td>
    </tr>
    <tr>
      <td style="background-color: white; padding: 40px 30px; border-radius: 0 0 16px 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h2 style="color: #5D2A3B; margin: 0 0 20px 0; font-size: 24px;">Ата-ана келісімін растау</h2>
        
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
          Сіздің балаңыз Anama қосымшасына тіркелді. Ата-ана келісімін растау үшін төмендегі кодты енгізіңіз:
        </p>
        
        <div style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">
          <p style="color: white; font-size: 14px; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">Сіздің растау кодыңыз</p>
          <p style="color: white; font-size: 42px; font-weight: bold; margin: 0; letter-spacing: 8px; font-family: monospace;">${otp}</p>
        </div>
        
        <div style="background-color: #FFF5F7; border-left: 4px solid #E8A5B3; padding: 15px; margin: 20px 0; border-radius: 0 8px 8px 0;">
          <p style="color: #5D2A3B; font-size: 14px; margin: 0;">
            <strong>⚠️ Маңызды:</strong> Код 10 минут жарамды. Бұл кодты ешкімге айтпаңыз.
          </p>
        </div>
        
        <p style="color: #999; font-size: 14px; line-height: 1.6;">
          Егер сіз бұл кодты сұрамаған болсаңыз, бұл хатты елемеңіз.
        </p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
          © ${new Date().getFullYear()} Anama. Балаңыздың эмоциялық қауіпсіздігі.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
      `,
    },
    en: {
      subject: 'Anama Verification Code',
      body: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #FDF8F9;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <tr>
      <td style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 16px 16px 0 0; padding: 40px 20px; text-align: center;">
        <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">🕊️ Anama</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Emotional Safety</p>
      </td>
    </tr>
    <tr>
      <td style="background-color: white; padding: 40px 30px; border-radius: 0 0 16px 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h2 style="color: #5D2A3B; margin: 0 0 20px 0; font-size: 24px;">Parental Consent Verification</h2>
        
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
          Your child has registered in the Anama app. To confirm parental consent, enter the code below:
        </p>
        
        <div style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">
          <p style="color: white; font-size: 14px; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">Your verification code</p>
          <p style="color: white; font-size: 42px; font-weight: bold; margin: 0; letter-spacing: 8px; font-family: monospace;">${otp}</p>
        </div>
        
        <div style="background-color: #FFF5F7; border-left: 4px solid #E8A5B3; padding: 15px; margin: 20px 0; border-radius: 0 8px 8px 0;">
          <p style="color: #5D2A3B; font-size: 14px; margin: 0;">
            <strong>⚠️ Important:</strong> This code is valid for 10 minutes. Do not share this code with anyone.
          </p>
        </div>
        
        <p style="color: #999; font-size: 14px; line-height: 1.6;">
          If you did not request this code, simply ignore this email.
        </p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
          © ${new Date().getFullYear()} Anama. Your child's emotional safety.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
      `,
    },
  };

  return templates[language] || templates['ru'];
};

/**
 * Firebase Function для отправки OTP на телефон родителя (SMS)
 * Вызывается из Flutter приложения
 */
exports.sendParentalConsentOtp = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // Только POST запросы
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
      const { phone, otp, language = 'ru' } = req.body;

      // Валидация
      if (!phone || !otp) {
        return res.status(400).json({ 
          error: 'Missing required fields',
          details: 'Phone and OTP are required' 
        });
      }

      // Валидация телефона (должен содержать только цифры)
      const phoneRegex = /^\d+$/;
      const normalizedPhone = phone.replace(/\D/g, '');
      
      if (!phoneRegex.test(normalizedPhone) || normalizedPhone.length < 10) {
        return res.status(400).json({ 
          error: 'Invalid phone format',
          details: 'Phone must contain at least 10 digits'
        });
      }

      // TODO: Интеграция с SMS сервисом (Twilio, SMS.ru, и т.д.)
      // Пока просто логируем - SMS сервис нужно настроить отдельно
      const smsMessage = language === 'kk' 
        ? `Anama растау коды: ${otp}. Код 10 минутқа жарамды.`
        : `Anama код подтверждения: ${otp}. Код действителен 10 минут.`;

      console.log(`📱 SMS для отправки на ${normalizedPhone}: ${smsMessage}`);
      
      // Здесь должна быть интеграция с SMS API
      // Например, через Twilio:
      // const twilio = require('twilio');
      // const client = twilio(accountSid, authToken);
      // await client.messages.create({
      //   body: smsMessage,
      //   to: `+${normalizedPhone}`,
      //   from: twilioPhoneNumber
      // });

      // Пока возвращаем успех, так как OTP уже сохранен в Firestore
      console.log(`✅ OTP SMS отправлен на ${normalizedPhone} (логирование)`);
      
      return res.status(200).json({ 
        success: true,
        message: 'OTP sent successfully',
        note: 'SMS service integration required - currently logging only'
      });

    } catch (error) {
      console.error('❌ Ошибка отправки SMS:', error);
      
      return res.status(500).json({ 
        error: 'Failed to send SMS',
        details: error.message 
      });
    }
  });
});

/**
 * Тестовая функция для проверки работы email
 */
exports.testEmail = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const config = getEmailConfig();
      
      return res.status(200).json({
        configured: !!(config.user && config.pass),
        user: config.user ? `${config.user.substring(0, 3)}***` : 'not set',
        message: config.user && config.pass 
          ? 'Email is configured' 
          : 'Email not configured. Run: firebase functions:config:set email.user="..." email.pass="..."'
      });
    } catch (error) {
      return res.status(500).json({ error: error.message });
    }
  });
});

// ============================================
// ЕЖЕДНЕВНЫЕ УВЕДОМЛЕНИЯ ДЛЯ РОДИТЕЛЕЙ
// ============================================

// API ключ Gemini
const GEMINI_API_KEY = 'AIzaSyCp_fuoIlNLJDW_1TbpcWzv4FFPL3Nea8o';

// Генератор разных фраз поддержки для мам
const getMomSupportPhrases = () => {
  const phrases = [
    'Вы большая молодец!',
    'Спасибо, что уделяете такое внимание развитию малыша',
    'Не забудьте позаботиться о себе',
    'Вы делаете важную работу',
    'Ваша забота — это основа здорового развития',
    'Вы прекрасная мама',
    'Ваше терпение и любовь творят чудеса',
    'Каждый день вы вкладываете в будущее вашего ребенка',
    'Вы создаете безопасное пространство для роста',
    'Ваша внимательность к деталям — это дар',
    'Вы учите ребенка важным вещам каждый день',
    'Ваша поддержка — это всё для малыша',
    'Вы находите время на развитие, и это ценно',
    'Ваша любовь формирует здоровый мозг ребенка',
    'Вы делаете мир лучше своим вниманием',
  ];
  return phrases;
};

// Генератор разных фраз для утренних уведомлений
const getMorningNotificationPhrases = () => {
  const phrases = [
    'Доброе утро! Вы большая молодец, что стараетесь понять своего малыша. Сегодня вас ждет новая игра для развития нейронных связей. Загляните в Anama! ✨',
    'Доброе утро! Спасибо, что уделяете такое внимание развитию малыша. Новое задание Serve & Return уже готово для вас! 🌟',
    'Доброе утро! Не забудьте позаботиться о себе сегодня. А пока — загляните в Anama за новым упражнением для развития речи! 💝',
    'Доброе утро! Вы делаете важную работу каждый день. Сегодня в Anama вас ждет интересная игра для развития мозга малыша! 🎯',
    'Доброе утро! Ваша забота — это основа здорового развития. Новое задание уже готово! Откройте Anama и начните день с пользой! 🌈',
    'Доброе утро! Вы прекрасная мама. Сегодня в Anama — новая игра для развития нейронных связей. Не пропустите! ✨',
    'Доброе утро! Ваше терпение и любовь творят чудеса. Загляните в Anama за сегодняшним заданием Serve & Return! 💫',
    'Доброе утро! Каждый день вы вкладываете в будущее вашего ребенка. Новое упражнение уже ждет вас в Anama! 🎨',
  ];
  return phrases;
};

// Генератор разных фраз для уведомлений о светофоре
const getTrafficLightNotificationPhrases = (riskLevel, change = null) => {
  if (change) {
    // Уведомление об изменении уровня
    const changePhrases = {
      improved: [
        `Отличные новости! Уровень тревоги и стресса вашего ребенка уменьшился. Продолжайте в том же духе! 🌟`,
        `Замечательно! Уровень тревоги снизился. Вы делаете всё правильно! 💚`,
        `Превосходно! Уровень стресса уменьшился. Ваша забота дает результаты! ✨`,
        `Отлично! Уровень тревоги снизился. Продолжайте поддерживать малыша! 🌈`,
      ],
      increased: [
        `Давайте проверим уровень тревоги вашего ребенка. Ваше внимание важно! 💛`,
        `Сегодня стоит обратить внимание на уровень стресса. Загляните в Anama! 🟡`,
        `Проверьте уровень тревоги вашего ребенка. Мы поможем разобраться! 💝`,
        `Уровень стресса требует внимания. Откройте Anama для анализа! 🔍`,
      ],
    };
    return changePhrases[change] || [];
  }
  
  // Обычные уведомления о проверке
  const phrases = [
    `Давайте проверим уровень тревоги вашего ребенка. Ваше внимание важно! 💛`,
    `Сегодня стоит обратить внимание на уровень стресса. Загляните в Anama! 🟡`,
    `Проверьте уровень тревоги вашего ребенка. Мы поможем разобраться! 💝`,
    `Уровень стресса требует внимания. Откройте Anama для анализа! 🔍`,
    `Как дела у вашего малыша? Проверьте уровень тревоги в Anama! 🌟`,
    `Важно знать, как чувствует себя ребенок. Проверьте светофор в Anama! 💚`,
  ];
  return phrases;
};

// Генерация "Фразы дня" через Gemini AI
async function generateDailyPhrase(language = 'ru') {
  try {
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    
    const systemPrompt = `Ты — экспертный ассистент по раннему развитию. Создай короткую, вдохновляющую фразу для мамы на ${language === 'ru' ? 'русском' : 'казахском'} языке. Фраза должна:
1. Поддерживать маму
2. Мотивировать заглянуть в приложение
3. Быть разной каждый день
4. Быть короткой (до 100 символов)

Примеры:
- "Доброе утро! Новое задание для развития речи уже ждет вас в Anama! ✨"
- "Сегодня в Anama — игра для развития нейронных связей. Вы большая молодец! 🌟"

Создай ТОЛЬКО фразу, без дополнительных объяснений.`;

    const result = await model.generateContent(systemPrompt);
    const response = await result.response;
    return response.text().trim();
  } catch (error) {
    console.error('Ошибка генерации фразы дня:', error);
    // Fallback на случайную фразу
    const fallbackPhrases = getMorningNotificationPhrases();
    return fallbackPhrases[Math.floor(Math.random() * fallbackPhrases.length)];
  }
}

// Cron-задача: ежедневно в 08:00 по времени Астаны (02:00 UTC)
// Астана = UTC+6, значит 08:00 Астаны = 02:00 UTC
exports.sendDailyNotifications = functions.pubsub
  .schedule('0 2 * * *') // Каждый день в 02:00 UTC (08:00 Астаны)
  .timeZone('Asia/Almaty')
  .onRun(async (context) => {
    console.log('🕐 Запуск ежедневных уведомлений в 08:00 Астаны');
    
    try {
      // Получаем всех родителей с детьми 0-5 лет
      const parentsSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'parent')
        .where('linkedUserId', '!=', null)
        .get();
      
      if (parentsSnapshot.empty) {
        console.log('Нет родителей для отправки уведомлений');
        return null;
      }
      
      // Генерируем фразу дня
      const dailyPhrase = await generateDailyPhrase('ru');
      console.log('📝 Сгенерирована фраза дня:', dailyPhrase);
      
      // Отправляем уведомления каждому родителю
      const promises = [];
      for (const parentDoc of parentsSnapshot.docs) {
        const parentData = parentDoc.data();
        const parentId = parentDoc.id;
        const linkedTeenId = parentData.linkedUserId;
        
        // Получаем данные ребенка для определения возраста
        let childAgeMonths = null;
        try {
          const teenDoc = await admin.firestore()
            .collection('users')
            .doc(linkedTeenId)
            .get();
          
          if (teenDoc.exists) {
            const teenData = teenDoc.data();
            if (teenData.age) {
              childAgeMonths = teenData.age * 12; // Преобразуем годы в месяцы
            }
          }
        } catch (e) {
          console.error(`Ошибка получения данных ребенка для родителя ${parentId}:`, e);
        }
        
        // Проверяем, есть ли FCM токен
        const fcmToken = parentData.fcmToken;
        if (!fcmToken) {
          console.log(`У родителя ${parentId} нет FCM токена, пропускаем`);
          continue;
        }
        
        // Отправляем уведомление
        const notification = {
          token: fcmToken,
          notification: {
            title: 'Anama',
            body: dailyPhrase,
          },
          data: {
            type: 'daily_phrase',
            timestamp: new Date().toISOString(),
          },
        };
        
        promises.push(
          admin.messaging().send(notification)
            .then(() => {
              console.log(`✅ Уведомление отправлено родителю ${parentId}`);
            })
            .catch((error) => {
              console.error(`❌ Ошибка отправки уведомления родителю ${parentId}:`, error);
            })
        );
      }
      
      await Promise.all(promises);
      console.log(`✅ Всего отправлено уведомлений: ${promises.length}`);
      
      return null;
    } catch (error) {
      console.error('❌ Ошибка в sendDailyNotifications:', error);
      return null;
    }
  });

// Функция для отправки уведомлений о светофоре
exports.sendTrafficLightNotification = functions.https.onCall(async (data, context) => {
  const { parentId, riskLevel, previousRiskLevel } = data;
  
  if (!parentId) {
    throw new functions.https.HttpsError('invalid-argument', 'parentId required');
  }
  
  try {
    // Получаем данные родителя
    const parentDoc = await admin.firestore()
      .collection('users')
      .doc(parentId)
      .get();
    
    if (!parentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Parent not found');
    }
    
    const parentData = parentDoc.data();
    const fcmToken = parentData.fcmToken;
    
    if (!fcmToken) {
      return { success: false, message: 'No FCM token' };
    }
    
    // Определяем тип уведомления
    let notificationBody;
    if (previousRiskLevel && previousRiskLevel !== riskLevel) {
      // Изменение уровня
      const change = riskLevel === 'green' ? 'improved' : 'increased';
      const phrases = getTrafficLightNotificationPhrases(riskLevel, change);
      notificationBody = phrases[Math.floor(Math.random() * phrases.length)];
    } else {
      // Обычное напоминание
      const phrases = getTrafficLightNotificationPhrases(riskLevel);
      notificationBody = phrases[Math.floor(Math.random() * phrases.length)];
    }
    
    // Отправляем уведомление
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Anama — Светофор',
        body: notificationBody,
      },
      data: {
        type: 'traffic_light',
        riskLevel: riskLevel,
        timestamp: new Date().toISOString(),
      },
    });
    
    return { success: true };
  } catch (error) {
    console.error('Ошибка отправки уведомления о светофоре:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ============================================
// БАЗА ДАННЫХ ДЛЯ КАРТОЧЕК SERVE AND RETURN (0-5 лет)
// ============================================

// Инициализация карточек Serve and Return для детей 0-5 лет
exports.initServeAndReturnCards = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const cardsRef = admin.firestore().collection('serve_and_return_cards');
      
      // Примеры карточек для разных возрастов (0-5 лет)
      const cards = [
        // 0-12 месяцев
        {
          ageRange: { min: 0, max: 12 },
          title: 'Зеркало улыбок',
          description: 'Когда ребенок улыбается, улыбнитесь в ответ и назовите его эмоцию',
          brainZone: '#КраснаяЗона_Социум',
          steps: [
            'Сядьте лицом к лицу с малышом на расстоянии 30 см',
            'Улыбнитесь и подождите — малыш улыбнется в ответ',
            'Повторите его мимику, добавьте звук "агу"',
            'Назовите эмоцию: "Ты улыбаешься! Мне тоже радостно!"',
          ],
          serveAndReturn: 'Когда ребенок указывает на предмет, мама должна его назвать и описать',
          careReminders: 'Проверьте влажность (норма 40-60%) и температуру (18-22°C). Важны прогулки на свежем воздухе!',
          momSupport: 'Вы большая молодец!',
          language: 'ru',
        },
        {
          ageRange: { min: 0, max: 12 },
          title: 'Назови предмет',
          description: 'Когда ребенок указывает на предмет, назовите его и опишите',
          brainZone: '#ЗеленаяЗона_Речь',
          steps: [
            'Ребенок указывает на предмет (игрушку, картинку)',
            'Назовите предмет: "Это мячик!"',
            'Опишите его: "Он красный и круглый"',
            'Повторите несколько раз, используя разные слова',
          ],
          serveAndReturn: 'Когда ребенок указывает на предмет, мама должна его назвать и описать — это база для развития речи',
          careReminders: 'Проверьте влажность (норма 40-60%) и температуру (18-22°C). Важны прогулки на свежем воздухе!',
          momSupport: 'Спасибо, что уделяете такое внимание развитию малыша',
          language: 'ru',
        },
        // 12-24 месяца
        {
          ageRange: { min: 12, max: 24 },
          title: 'Башня вместе',
          description: 'Стройте башню из кубиков по очереди, комментируя действия',
          brainZone: '#ОранжеваяЗона_Моторика',
          steps: [
            'Возьмите кубики или стаканчики',
            'Положите первый кубик и скажите "Твоя очередь!"',
            'Похвалите попытку, даже если башня упала',
            'Стройте по очереди, комментируя: "Мой кубик, твой кубик"',
          ],
          serveAndReturn: 'Когда ребенок кладет кубик, мама отвечает похвалой и добавляет свой кубик',
          careReminders: 'Проверьте влажность (норма 40-60%) и температуру (18-22°C). Важны прогулки на свежем воздухе!',
          momSupport: 'Не забудьте позаботиться о себе',
          language: 'ru',
        },
        // 24-36 месяцев
        {
          ageRange: { min: 24, max: 36 },
          title: 'Что это?',
          description: 'Показывайте предметы и спрашивайте "Что это?", помогая ребенку назвать',
          brainZone: '#ЗеленаяЗона_Речь',
          steps: [
            'Покажите предмет и спросите: "Что это?"',
            'Если ребенок не знает, назовите сами: "Это машина!"',
            'Повторите вопрос через минуту',
            'Хвалите любую попытку ответить',
          ],
          serveAndReturn: 'Когда ребенок пытается назвать предмет, мама подтверждает и расширяет ответ',
          careReminders: 'Проверьте влажность (норма 40-60%) и температуру (18-22°C). Важны прогулки на свежем воздухе!',
          momSupport: 'Вы делаете важную работу',
          language: 'ru',
        },
        // 36-60 месяцев
        {
          ageRange: { min: 36, max: 60 },
          title: 'Придумай историю',
          description: 'Начните историю и предложите ребенку продолжить',
          brainZone: '#ЖелтаяЗона_Творчество',
          steps: [
            'Начните: "Жил-был маленький зайчик..."',
            'Спросите: "Что он делал?"',
            'Продолжите историю по очереди',
            'Закончите вместе счастливым концом',
          ],
          serveAndReturn: 'Когда ребенок добавляет идею, мама развивает её и задает следующий вопрос',
          careReminders: 'Проверьте влажность (норма 40-60%) и температуру (18-22°C). Важны прогулки на свежем воздухе!',
          momSupport: 'Ваша забота — это основа здорового развития',
          language: 'ru',
        },
      ];
      
      // Добавляем карточки в базу данных
      const batch = admin.firestore().batch();
      cards.forEach((card, index) => {
        const cardRef = cardsRef.doc();
        batch.set(cardRef, {
          ...card,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      
      await batch.commit();
      
      res.status(200).json({
        success: true,
        message: `Добавлено ${cards.length} карточек Serve and Return`,
        cards: cards.length,
      });
    } catch (error) {
      console.error('Ошибка инициализации карточек:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// Получение карточек Serve and Return для определенного возраста
exports.getServeAndReturnCards = functions.https.onCall(async (data, context) => {
  const { ageMonths } = data;
  
  if (!ageMonths || ageMonths < 0 || ageMonths > 60) {
    throw new functions.https.HttpsError('invalid-argument', 'ageMonths must be between 0 and 60');
  }
  
  try {
    const cardsSnapshot = await admin.firestore()
      .collection('serve_and_return_cards')
      .where('ageRange.min', '<=', ageMonths)
      .where('ageRange.max', '>=', ageMonths)
      .get();
    
    const cards = cardsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    return { success: true, cards };
  } catch (error) {
    console.error('Ошибка получения карточек:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ============================================
// ИНИЦИАЛИЗАЦИЯ КЛИНИЧЕСКИХ ТЕСТОВ PHQ-9 И GAD-7
// ============================================

// Инициализация вопросов PHQ-9
exports.initPhq9Questions = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const questionsRef = admin.firestore().collection('phq9_questions');
      
      const questions = [
        {
          id: 'phq9_1',
          text: 'За последние 2 недели, как часто тебя беспокоило плохое настроение, подавленность или безнадежность?',
          order: 1,
          language: 'ru',
        },
        {
          id: 'phq9_2',
          text: 'За последние 2 недели, как часто тебя беспокоило отсутствие интереса или удовольствия от того, чем ты обычно занимаешься?',
          order: 2,
          language: 'ru',
        },
        {
          id: 'phq9_3',
          text: 'За последние 2 недели, как часто у тебя были проблемы с засыпанием или сном (слишком долгий сон или беспокойный сон)?',
          order: 3,
          language: 'ru',
        },
        {
          id: 'phq9_4',
          text: 'За последние 2 недели, как часто ты чувствовал(а) усталость или нехватку энергии?',
          order: 4,
          language: 'ru',
        },
        {
          id: 'phq9_5',
          text: 'За последние 2 недели, как часто у тебя был плохой аппетит или ты переедал(а)?',
          order: 5,
          language: 'ru',
        },
        {
          id: 'phq9_6',
          text: 'За последние 2 недели, как часто ты чувствовал(а) себя плохо из-за того, что ты плохой человек, или что ты подвел(а) себя или свою семью?',
          order: 6,
          language: 'ru',
        },
        {
          id: 'phq9_7',
          text: 'За последние 2 недели, как часто у тебя были проблемы с концентрацией внимания (например, при чтении или просмотре телевизора)?',
          order: 7,
          language: 'ru',
        },
        {
          id: 'phq9_8',
          text: 'За последние 2 недели, двигался ли ты или говорил так медленно, что другие могли это заметить? Или наоборот — был настолько беспокойным(ой) или суетливым, что двигался намного больше обычного?',
          order: 8,
          language: 'ru',
        },
        {
          id: 'phq9_9',
          text: 'За последние 2 недели, возникали ли у тебя мысли о том, что лучше было бы умереть, или о причинении себе вреда?',
          order: 9,
          language: 'ru',
        },
      ];
      
      const batch = admin.firestore().batch();
      questions.forEach((question) => {
        const questionRef = questionsRef.doc(question.id);
        batch.set(questionRef, {
          ...question,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      
      await batch.commit();
      
      res.status(200).json({
        success: true,
        message: `Добавлено ${questions.length} вопросов PHQ-9`,
        count: questions.length,
      });
    } catch (error) {
      console.error('Ошибка инициализации PHQ-9:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// Инициализация вопросов GAD-7
exports.initGad7Questions = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const questionsRef = admin.firestore().collection('gad7_questions');
      
      const questions = [
        {
          id: 'gad7_1',
          text: 'За последние 2 недели, как часто тебя беспокоило чувство нервозности, тревоги или напряжения?',
          order: 1,
          language: 'ru',
        },
        {
          id: 'gad7_2',
          text: 'За последние 2 недели, как часто тебя беспокоило то, что ты не мог(ла) остановить или контролировать беспокойство?',
          order: 2,
          language: 'ru',
        },
        {
          id: 'gad7_3',
          text: 'За последние 2 недели, как часто тебя беспокоило чрезмерное беспокойство о разных вещах?',
          order: 3,
          language: 'ru',
        },
        {
          id: 'gad7_4',
          text: 'За последние 2 недели, как часто тебе было трудно расслабиться?',
          order: 4,
          language: 'ru',
        },
        {
          id: 'gad7_5',
          text: 'За последние 2 недели, как часто ты был(а) настолько беспокойным(ой), что тебе было трудно усидеть на месте?',
          order: 5,
          language: 'ru',
        },
        {
          id: 'gad7_6',
          text: 'За последние 2 недели, как часто тебя беспокоила раздражительность или легкость возникновения злости?',
          order: 6,
          language: 'ru',
        },
        {
          id: 'gad7_7',
          text: 'За последние 2 недели, как часто тебя беспокоило чувство страха, как будто должно произойти что-то ужасное?',
          order: 7,
          language: 'ru',
        },
      ];
      
      const batch = admin.firestore().batch();
      questions.forEach((question) => {
        const questionRef = questionsRef.doc(question.id);
        batch.set(questionRef, {
          ...question,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      
      await batch.commit();
      
      res.status(200).json({
        success: true,
        message: `Добавлено ${questions.length} вопросов GAD-7`,
        count: questions.length,
      });
    } catch (error) {
      console.error('Ошибка инициализации GAD-7:', error);
      res.status(500).json({ error: error.message });
    }
  });
});


/**
 * Proxy для загрузки изображений знаменитостей (обход CORS)
 * Использование: /proxyImage?url=https://example.com/image.jpg
 */
exports.proxyImage = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const imageUrl = req.query.url;

      if (!imageUrl) {
        return res.status(400).json({ 
          error: 'URL параметр обязателен',
          usage: 'GET /proxyImage?url=https://example.com/image.jpg'
        });
      }

      // Валидация URL
      let parsedUrl;
      try {
        parsedUrl = new URL(imageUrl);
      } catch (e) {
        return res.status(400).json({ 
          error: 'Некорректный URL',
          url: imageUrl
        });
      }

      // Загружаем изображение
      const response = await axios.get(imageUrl, {
        responseType: 'arraybuffer',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
        timeout: 10000, // 10 секунд таймаут
      });

      // Определяем content-type
      const contentType = response.headers['content-type'] || 'image/jpeg';
      
      // Отдаем изображение с CORS заголовками
      res.set({
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Cache-Control': 'public, max-age=31536000', // Кэшируем на год
      });

      res.send(Buffer.from(response.data));
      
    } catch (error) {
      console.error('Ошибка загрузки изображения:', error.message);
      console.error('URL:', req.query.url);
      
      res.status(500).json({ 
        error: 'Ошибка загрузки изображения',
        message: error.message,
        url: req.query.url
      });
    }
  });
});

// ============================================================================
// УВЕДОМЛЕНИЯ О ЧАТЕ
// ============================================================================

// Cloud Function для отправки push-уведомлений о новых сообщениях в чате
exports.sendChatNotification = functions.firestore
  .document('chat_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    
    // Проверяем, не отправлено ли уже
    if (notificationData.sent) {
      console.log('Уведомление уже отправлено');
      return null;
    }

    const { fcmToken, title, body, data, recipientId } = notificationData;

    if (!fcmToken) {
      console.error('❌ FCM токен не найден для пользователя:', recipientId);
      return null;
    }

    try {
      // Отправляем push-уведомление через FCM
      const message = {
        notification: {
          title: title || '💬 Новое сообщение',
          body: body || 'У вас новое сообщение',
        },
        data: data || {},
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: title || '💬 Новое сообщение',
                body: body || 'У вас новое сообщение',
              },
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Уведомление о чате отправлено:', response);

      // Отмечаем уведомление как отправленное
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmMessageId: response,
      });

      return null;
    } catch (error) {
      console.error('❌ Ошибка отправки уведомления о чате:', error);
      
      // Обновляем статус ошибки
      await snap.ref.update({
        sent: false,
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

// Cloud Function для отправки уведомлений при новом сообщении в чате
exports.onChatMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const { chatId } = context.params;
    const { senderId, text, senderName } = messageData;

    try {
      // Получаем данные чата
      const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        console.error('Чат не найден:', chatId);
        return null;
      }

      const chatData = chatDoc.data();
      const { participants, psychologistId, userId } = chatData;

      // Определяем получателя (тот, кто не отправитель)
      const recipientId = participants.find(id => id !== senderId);
      if (!recipientId) {
        console.error('Получатель не найден');
        return null;
      }

      // Проверяем, не является ли отправитель получателем (избегаем уведомлений себе)
      if (recipientId === senderId) {
        return null;
      }

      // Получаем FCM токен получателя
      let recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
      let recipientData = recipientDoc.data();
      
      // Если не найден в users, проверяем psychologists
      if (!recipientDoc.exists) {
        recipientDoc = await admin.firestore().collection('psychologists').doc(recipientId).get();
        recipientData = recipientDoc.data();
      }

      const fcmToken = recipientData?.fcmToken;
      if (!fcmToken) {
        console.log('FCM токен не найден для получателя:', recipientId);
        return null;
      }

      // Создаем уведомление
      const notificationTitle = senderName 
        ? `💬 ${senderName}`
        : '💬 Новое сообщение';
      
      const notificationBody = text.length > 50 
        ? `${text.substring(0, 50)}...`
        : text;

      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: 'chat_message',
          chatId: chatId,
          senderId: senderId,
          action: 'open_chat',
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
            sound: 'default',
            priority: 'high',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: notificationTitle,
                body: notificationBody,
              },
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Push-уведомление о чате отправлено:', response);

      // Сохраняем в коллекцию уведомлений для истории
      await admin.firestore().collection('chat_notifications').add({
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName || 'Пользователь',
        message: text,
        chatId: chatId,
        fcmToken: fcmToken,
        title: notificationTitle,
        body: notificationBody,
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmMessageId: response,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error('❌ Ошибка обработки нового сообщения в чате:', error);
      return null;
    }
  });

// ============================================
// СБРОС ПАРОЛЯ ПОДРОСТКОВ
// ============================================

/**
 * Cloud Function: отправка email при создании документа в коллекции mail
 * Используется для отправки кодов сброса пароля родителям
 */
exports.onMailCreated = functions.firestore
  .document('mail/{mailId}')
  .onCreate(async (snap, context) => {
    const mailData = snap.data();
    const { mailId } = context.params;

    console.log('📧 Новый email для отправки:', mailId);

    try {
      const transporter = createTransporter();
      if (!transporter) {
        console.error('❌ Email транспорт не настроен');
        await snap.ref.update({
          'delivery.state': 'ERROR',
          'delivery.error': 'Email not configured',
          'delivery.endTime': admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }

      const { fromName, from } = getEmailConfig();

      // Отправляем email
      const mailOptions = {
        from: `"${fromName}" <${from}>`,
        to: mailData.to,
        subject: mailData.message?.subject || 'Anama',
        html: mailData.message?.html || mailData.message?.text || '',
        text: mailData.message?.text || '',
      };

      await transporter.sendMail(mailOptions);
      console.log('✅ Email отправлен на:', mailData.to);

      // Обновляем статус
      await snap.ref.update({
        'delivery.state': 'SUCCESS',
        'delivery.endTime': admin.firestore.FieldValue.serverTimestamp(),
        'delivery.leaseExpireTime': null,
      });

      return null;
    } catch (error) {
      console.error('❌ Ошибка отправки email:', error);
      
      await snap.ref.update({
        'delivery.state': 'ERROR',
        'delivery.error': error.message,
        'delivery.endTime': admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

/**
 * Cloud Function: обработка запросов на сброс пароля подростков
 * Читает password_reset_requests и обновляет пароль через Admin SDK
 */
exports.processPasswordResetRequests = functions.firestore
  .document('password_reset_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    const { requestId } = context.params;

    console.log('🔐 Обработка запроса сброса пароля:', requestId);

    // Проверяем, не обработан ли уже
    if (requestData.processed) {
      console.log('Запрос уже обработан');
      return null;
    }

    try {
      const { teenId, fakeEmail, newPassword } = requestData;

      if (!teenId || !fakeEmail || !newPassword) {
        throw new Error('Отсутствуют обязательные поля');
      }

      // Обновляем пароль через Firebase Admin SDK
      await admin.auth().updateUser(teenId, {
        password: newPassword,
      });

      console.log('✅ Пароль успешно обновлен для:', teenId);

      // Помечаем запрос как обработанный
      await snap.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
      });

      // Удаляем пароль из документа (безопасность)
      await snap.ref.update({
        newPassword: admin.firestore.FieldValue.delete(),
      });

      return null;
    } catch (error) {
      console.error('❌ Ошибка обработки сброса пароля:', error);
      
      await snap.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        success: false,
        error: error.message,
      });
      
      return null;
    }
  });

/**
 * HTTP функция для запроса сброса пароля подростка
 * Может вызываться напрямую из приложения
 */
exports.requestTeenPasswordReset = functions.https.onCall(async (data, context) => {
  const { nickname } = data;

  if (!nickname) {
    throw new functions.https.HttpsError('invalid-argument', 'Nickname is required');
  }

  try {
    const db = admin.firestore();
    
    // Ищем подростка по никнейму
    const teenSnapshot = await db
      .collection('users')
      .where('nickname', '==', nickname.toLowerCase())
      .where('role', '==', 'teen')
      .limit(1)
      .get();

    if (teenSnapshot.empty) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const teenDoc = teenSnapshot.docs[0];
    const teenData = teenDoc.data();
    const teenId = teenDoc.id;

    // Ищем email родителя
    let parentEmail = null;
    
    // Сначала проверяем связанного родителя
    const linkedParentId = teenData.linkedUserId;
    if (linkedParentId) {
      const parentDoc = await db.collection('users').doc(linkedParentId).get();
      if (parentDoc.exists) {
        parentEmail = parentDoc.data().email;
      }
    }
    
    // Если нет связанного родителя, берём email из регистрации
    if (!parentEmail) {
      parentEmail = teenData.parentEmail;
    }

    if (!parentEmail) {
      throw new functions.https.HttpsError('failed-precondition', 'Parent email not found');
    }

    // Генерируем 6-значный код
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 час

    // Сохраняем код
    await db.collection('password_reset_codes').doc(teenId).set({
      code: resetCode,
      teenId: teenId,
      nickname: nickname.toLowerCase(),
      parentEmail: parentEmail,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt,
      used: false,
    });

    // Отправляем email
    const transporter = createTransporter();
    if (transporter) {
      const { fromName, from } = getEmailConfig();
      
      await transporter.sendMail({
        from: `"${fromName}" <${from}>`,
        to: parentEmail,
        subject: 'Anama: Код для сброса пароля ребёнка',
        html: `
          <div style="font-family: -apple-system, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); padding: 30px; border-radius: 16px 16px 0 0; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 28px;">🕊️ Anama</h1>
              <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0;">Эмоциональная безопасность</p>
            </div>
            <div style="background: white; padding: 30px; border-radius: 0 0 16px 16px; border: 1px solid #eee; border-top: none;">
              <p style="color: #333; font-size: 16px;">Здравствуйте!</p>
              <p style="color: #666; font-size: 16px;">Ваш ребёнок (<b>${nickname}</b>) запросил сброс пароля в приложении Anama.</p>
              
              <div style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 12px; padding: 25px; text-align: center; margin: 25px 0;">
                <p style="color: white; font-size: 14px; margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 1px;">Код для сброса пароля</p>
                <p style="color: white; font-size: 36px; font-weight: bold; margin: 0; letter-spacing: 8px; font-family: monospace;">${resetCode}</p>
              </div>
              
              <div style="background: #FFF5F7; border-left: 4px solid #E8A5B3; padding: 15px; border-radius: 0 8px 8px 0;">
                <p style="color: #5D2A3B; font-size: 14px; margin: 0;">
                  ⏰ Код действителен <b>1 час</b>. Сообщите его ребёнку для завершения сброса пароля.
                </p>
              </div>
              
              <p style="color: #999; font-size: 14px; margin-top: 20px;">
                Если вы не запрашивали сброс пароля, просто проигнорируйте это письмо.
              </p>
              
              <hr style="border: none; border-top: 1px solid #eee; margin: 25px 0;">
              <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                © ${new Date().getFullYear()} Anama — эмоциональная безопасность для подростков
              </p>
            </div>
          </div>
        `,
      });
    } else {
      // Fallback: добавляем в коллекцию mail
      await db.collection('mail').add({
        to: parentEmail,
        message: {
          subject: 'Anama: Код для сброса пароля ребёнка',
          html: `<p>Код для сброса пароля: <b>${resetCode}</b></p><p>Код действителен 1 час.</p>`,
        },
      });
    }

    // Маскируем email для возврата
    const maskedEmail = maskEmail(parentEmail);
    
    return { 
      success: true, 
      maskedEmail: maskedEmail,
    };
  } catch (error) {
    console.error('Ошибка запроса сброса пароля:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Вспомогательная функция для маскирования email
function maskEmail(email) {
  const parts = email.split('@');
  if (parts.length !== 2) return '***@***.***';
  
  const name = parts[0];
  const domain = parts[1];
  
  let maskedName;
  if (name.length <= 2) {
    maskedName = name[0] + '***';
  } else {
    maskedName = name[0] + '***' + name[name.length - 1];
  }
  
  const domainParts = domain.split('.');
  let maskedDomain;
  if (domainParts.length > 0 && domainParts[0].length > 1) {
    maskedDomain = domainParts[0][0] + '***';
    if (domainParts.length > 1) {
      maskedDomain += '.' + domainParts.slice(1).join('.');
    }
  } else {
    maskedDomain = domain;
  }
  
  return maskedName + '@' + maskedDomain;
}

// ============================================
// ОБРАТНАЯ СВЯЗЬ - отправка email при создании
// ============================================

/**
 * Cloud Function: onFeedbackCreated
 * Отправляет email на theanama.inc@gmail.com при создании нового фидбека
 */
exports.onFeedbackCreated = functions.firestore
  .document('feedback/{feedbackId}')
  .onCreate(async (snap, context) => {
    const feedbackData = snap.data();
    const { feedbackId } = context.params;

    console.log('📬 Новая обратная связь:', feedbackId);

    try {
      const transporter = createTransporter();
      if (!transporter) {
        console.error('❌ Email транспорт не настроен');
        return null;
      }

      const { fromName } = getEmailConfig();

      // Категории на русском
      const categoryLabels = {
        'general': 'Общий вопрос',
        'bug': 'Сообщение об ошибке',
        'feature': 'Предложение функции',
        'complaint': 'Жалоба',
        'data': 'Вопрос о данных',
        'other': 'Другое',
      };

      const categoryLabel = categoryLabels[feedbackData.category] || feedbackData.category;
      const createdAt = feedbackData.createdAt?.toDate?.() || new Date();

      // HTML шаблон письма
      const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #7c3aed, #a855f7); color: white; padding: 20px; border-radius: 12px 12px 0 0; }
    .content { background: #f9fafb; padding: 24px; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 12px 12px; }
    .field { margin-bottom: 16px; }
    .label { font-weight: 600; color: #6b7280; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }
    .value { margin-top: 4px; padding: 12px; background: white; border-radius: 8px; border: 1px solid #e5e7eb; }
    .message-box { white-space: pre-wrap; }
    .category-badge { display: inline-block; padding: 4px 12px; background: #7c3aed; color: white; border-radius: 20px; font-size: 12px; }
    .footer { margin-top: 20px; padding-top: 16px; border-top: 1px solid #e5e7eb; font-size: 12px; color: #9ca3af; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2 style="margin: 0;">📬 Новая обратная связь</h2>
      <p style="margin: 8px 0 0 0; opacity: 0.9;">Приложение Anama</p>
    </div>
    <div class="content">
      <div class="field">
        <div class="label">Категория</div>
        <div style="margin-top: 8px;">
          <span class="category-badge">${categoryLabel}</span>
        </div>
      </div>
      
      <div class="field">
        <div class="label">От пользователя</div>
        <div class="value">
          <strong>${feedbackData.userName || 'Аноним'}</strong><br>
          ${feedbackData.userEmail || 'Email не указан'}<br>
          <small style="color: #9ca3af;">ID: ${feedbackData.userId || 'Не авторизован'}</small>
        </div>
      </div>
      
      <div class="field">
        <div class="label">Тема</div>
        <div class="value">${feedbackData.subject || 'Без темы'}</div>
      </div>
      
      <div class="field">
        <div class="label">Сообщение</div>
        <div class="value message-box">${feedbackData.message || 'Пустое сообщение'}</div>
      </div>
      
      <div class="field">
        <div class="label">Дата и время</div>
        <div class="value">${createdAt.toLocaleString('ru-RU', { 
          timeZone: 'Asia/Almaty',
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        })}</div>
      </div>
      
      <div class="field">
        <div class="label">Платформа</div>
        <div class="value">${feedbackData.platform || 'Не указана'}</div>
      </div>
      
      <div class="footer">
        <p>Это автоматическое уведомление от приложения Anama.</p>
        <p>Для ответа пользователю используйте email: ${feedbackData.userEmail || 'не указан'}</p>
      </div>
    </div>
  </div>
</body>
</html>
      `;

      // Отправляем email
      const mailOptions = {
        from: `"${fromName}" <theanama.inc@gmail.com>`,
        to: 'theanama.inc@gmail.com',
        replyTo: feedbackData.userEmail || undefined,
        subject: `[Anama Feedback] ${categoryLabel}: ${feedbackData.subject || 'Без темы'}`,
        html: htmlContent,
        text: `
Новая обратная связь от приложения Anama

Категория: ${categoryLabel}
От: ${feedbackData.userName || 'Аноним'} (${feedbackData.userEmail || 'Email не указан'})
Тема: ${feedbackData.subject || 'Без темы'}

Сообщение:
${feedbackData.message || 'Пустое сообщение'}

---
Дата: ${createdAt.toLocaleString('ru-RU')}
ID пользователя: ${feedbackData.userId || 'Не авторизован'}
Платформа: ${feedbackData.platform || 'Не указана'}
        `,
      };

      await transporter.sendMail(mailOptions);
      console.log('✅ Email с обратной связью отправлен на theanama.inc@gmail.com');

      // Обновляем статус в документе
      await snap.ref.update({
        emailSent: true,
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error('❌ Ошибка отправки email обратной связи:', error);
      
      // Помечаем как не отправленное
      await snap.ref.update({
        emailSent: false,
        emailError: error.message,
      });
      
      return null;
    }
  });
