import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [input, setInput] = useState('');
  const [step, setStep] = useState('content'); // 'content' 或 'duration'
  const [duration, setDuration] = useState('');
  const [records, setRecords] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [timeoutId, setTimeoutId] = useState(null);

  // 5秒超时处理
  useEffect(() => {
    let timer;
    if (step === 'duration') {
      timer = setTimeout(() => {
        // 10秒后自动提交，无时间记录
        submitRecord(input, '');
      }, 10000);
      setTimeoutId(timer);
    }
    return () => {
      if (timer) {
        clearTimeout(timer);
      }
    };
  }, [step, input]);

  // 加载今天的记录
  useEffect(() => {
    fetchTodayRecords();
  }, []);

  const fetchTodayRecords = async () => {
    try {
      const response = await fetch('http://localhost:8080/api/records');
      const data = await response.json();
      if (data.data) {
        setRecords(data.data);
      }
    } catch (error) {
      console.error('获取记录失败:', error);
    }
  };

  const submitRecord = async (content, time) => {
    // 清除超时定时器，防止重复提交
    if (timeoutId) {
      clearTimeout(timeoutId);
      setTimeoutId(null);
    }
    
    setIsLoading(true);
    try {
      const response = await fetch('http://localhost:8080/api/record', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: content,
          duration: time
        }),
      });

      const data = await response.json();
      if (response.ok) {
        setMessage('记录保存成功！');
        setInput('');
        setDuration('');
        setStep('content');
        // 重新获取记录
        fetchTodayRecords();
      } else {
        setMessage('保存失败: ' + (data.error || '未知错误'));
      }
    } catch (error) {
      setMessage('网络错误: ' + error.message);
    } finally {
      setIsLoading(false);
      // 3秒后清除消息
      setTimeout(() => setMessage(''), 3000);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      if (step === 'content') {
        if (input.trim()) {
          setStep('duration');
        }
      } else if (step === 'duration') {
        submitRecord(input, duration);
      }
    }
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('zh-CN', { 
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  return (
    <div className="App">
      <div className="container">
        <h1>时间记录器</h1>
        
        <div className="input-section">
          {step === 'content' ? (
            <div>
              <p className="prompt">请输入内容：</p>
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="输入你要记录的内容..."
                className="input-field"
                autoFocus
                disabled={isLoading}
              />
            </div>
          ) : (
            <div>
              <p className="prompt">请输入花费时间（分钟）：</p>
              <p className="sub-prompt">10秒内未输入将自动忽略时间</p>
              <input
                type="number"
                value={duration}
                onChange={(e) => setDuration(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="例如: 30"
                className="input-field"
                autoFocus
                disabled={isLoading}
              />
              <p className="current-content">当前内容: {input}</p>
            </div>
          )}
        </div>

        {message && (
          <div className={`message ${message.includes('成功') ? 'success' : 'error'}`}>
            {message}
          </div>
        )}

        <div className="records-section">
          <h2>今日记录</h2>
          {records.length === 0 ? (
            <p className="no-records">暂无记录</p>
          ) : (
            <div className="records-list">
              {records.map((record, index) => (
                <div key={index} className="record-item">
                  <div className="record-content">{record.content}</div>
                  <div className="record-meta">
                    <span className="record-time">{formatTime(record.timestamp)}</span>
                    {record.duration && (
                      <span className="record-duration">{record.duration}分钟</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;