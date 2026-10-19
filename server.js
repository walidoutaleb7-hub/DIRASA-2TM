const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(cors());
app.use(express.json());

// سيتم قراءة المفتاح من إعدادات Render (Environment Variables) وليس من الكود
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

app.post('/api/chat', async (req, res) => {
  try {
    const { message, history } = req.body;
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-3.6-flash',
      systemInstruction: 'أنت "DIRASA AI"، مساعد دراسي خارق الذكاء. أجب بالعربية الفصحى المبسطة وبخطوات مرقمة.'
    });

    const chat = model.startChat({ history: history || [] });
    const result = await chat.sendMessage(message);
    const response = await result.response;
    res.json({ reply: response.text() });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'حدث خطأ في الخادم' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
