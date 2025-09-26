package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type RecordRequest struct {
	Content  string `json:"content" binding:"required"`
	Duration string `json:"duration"` // 花费时间（分钟），可为空
}

type LogEntry struct {
	Content   string `json:"content"`
	Duration  string `json:"duration"`
	Timestamp string `json:"timestamp"`
}

func main() {
	// 创建日志目录
	logDir := "./logs"
	if err := os.MkdirAll(logDir, 0755); err != nil {
		log.Fatal("创建日志目录失败:", err)
	}

	r := gin.Default()

	// 设置CORS
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// 记录数据的API端点
	r.POST("/api/record", recordHandler)

	// 获取记录的API端点
	r.GET("/api/records", getRecordsHandler)

	// 获取指定日期的记录
	r.GET("/api/records/:date", getRecordsByDateHandler)

	// 静态文件服务（可选，用于前端部署）
	r.Static("/static", "./static")

	fmt.Println("服务器启动在 http://localhost:8080")
	r.Run(":8080")
}

func recordHandler(c *gin.Context) {
	var req RecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求数据"})
		return
	}

	// 创建日志条目
	now := time.Now()
	entry := LogEntry{
		Content:   req.Content,
		Duration:  req.Duration,
		Timestamp: now.Format("2006-01-02 15:04:05"),
	}

	// 写入日志文件
	if err := writeToLogFile(entry, now); err != nil {
		log.Printf("写入日志文件失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "保存记录失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "记录保存成功",
		"data":    entry,
	})
}

func getRecordsHandler(c *gin.Context) {
	// 获取今天的记录
	today := time.Now()
	records, err := getRecordsByDate(today)
	if err != nil {
		log.Printf("获取记录失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取记录失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": records,
		"date": today.Format("2006-01-02"),
	})
}

func getRecordsByDateHandler(c *gin.Context) {
	dateStr := c.Param("date")
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的日期格式"})
		return
	}

	records, err := getRecordsByDate(date)
	if err != nil {
		log.Printf("获取记录失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取记录失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": records,
		"date": dateStr,
	})
}

func writeToLogFile(entry LogEntry, timestamp time.Time) error {
	// 创建月份目录
	monthDir := filepath.Join("./logs", timestamp.Format("2006-01"))
	if err := os.MkdirAll(monthDir, 0755); err != nil {
		return fmt.Errorf("创建月份目录失败: %v", err)
	}

	// 日志文件名
	filename := filepath.Join(monthDir, timestamp.Format("2006-01-02")+".log")

	// 格式化日志行：内容|花费时间|时间戳
	logLine := fmt.Sprintf("%s|%s|%s\n", entry.Content, entry.Duration, entry.Timestamp)

	// 追加写入文件
	file, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("打开日志文件失败: %v", err)
	}
	defer file.Close()

	if _, err := file.WriteString(logLine); err != nil {
		return fmt.Errorf("写入日志文件失败: %v", err)
	}

	return nil
}

func getRecordsByDate(date time.Time) ([]LogEntry, error) {
	// 构建日志文件路径
	monthDir := filepath.Join("./logs", date.Format("2006-01"))
	filename := filepath.Join(monthDir, date.Format("2006-01-02")+".log")

	// 检查文件是否存在
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		return []LogEntry{}, nil // 返回空列表，不是错误
	}

	// 读取文件内容
	content, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("读取日志文件失败: %v", err)
	}

	// 解析日志行
	var records []LogEntry
	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// 解析格式：内容|花费时间|时间戳
		parts := strings.Split(line, "|")
		if len(parts) != 3 {
			continue // 跳过格式不正确的行
		}

		records = append(records, LogEntry{
			Content:   parts[0],
			Duration:  parts[1],
			Timestamp: parts[2],
		})
	}

	return records, nil
}
