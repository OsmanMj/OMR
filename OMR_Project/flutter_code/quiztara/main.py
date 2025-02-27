from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
import cv2
import numpy as np
import os
import base64
from datetime import datetime

app = FastAPI()

OUTPUT_DIR = "processed_images" 
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

@app.post("/process_image") 
async def process_image(  
    image: UploadFile = File(...),
    answer_key: str = Form(...),
    num_questions: int = Form(...)  
):
    print("Alınan istek:")
    print(f"Resim: {image.filename if image else 'Görüntü alınamadı'}")
    print(f"Cevap anahtarı: {answer_key if answer_key else 'Eksik cevap anahtarı'}")
    print(f"Soru Sayısı: {num_questions}")

    #   
    if not image:
        return JSONResponse({"error": "Eksik resim dosyası"}, status_code=400)
    if not answer_key:
        return JSONResponse({"error": "Cevap anahtarı eksik"}, status_code=400)
    if num_questions not in [5, 10, 20]:
        return JSONResponse(
            {"error": "Geçersiz Soru Sayısı. Sadece 5 , 10 veya 20 destekleniyor."},
            status_code=400
        )

    try:
        
        try:
            answer_key_list = [int(x) for x in answer_key.split(",")] 
        except ValueError:
            return JSONResponse(
                {"error": "answer_key için geçersiz biçim. Virgülle ayrılmış bir tamsayı listesi olmalıdır."},
                status_code=400
            )

        if len(answer_key_list) != num_questions:
            return JSONResponse(
                {"error": "Cevap anahtarı uzunluğu soru sayısına uymuyor."},
                status_code=400
            )

        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            return JSONResponse({"error": "Geçersiz resim dosyası"}, status_code=400)

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        edges = cv2.Canny(blurred, 50, 150)

        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        biggest_contour = None
        max_area = 0
        for contour in contours:
            area = cv2.contourArea(contour)
            approx = cv2.approxPolyDP(contour, 0.02 * cv2.arcLength(contour, True), True)
            if area > 2000 and len(approx) == 4:  
                if area > max_area:
                    biggest_contour = approx
                    max_area = area

        if biggest_contour is None:
            return JSONResponse({"error": "OMR sayfası algılanmadı"}, status_code=400)

        points = np.array([point[0] for point in biggest_contour])
        points = sorted(points, key=lambda x: x[0] + x[1]) 
        src_points = np.float32(points)
        dst_points = np.float32([
            [0, 0],
            [500, 0],
            [0, 700],
            [500, 700]
        ])
        matrix = cv2.getPerspectiveTransform(src_points, dst_points)
        warped = cv2.warpPerspective(img, matrix, (500, 700))

        warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
        _, thresh = cv2.threshold(warped_gray, 150, 255, cv2.THRESH_BINARY_INV)

        rows = num_questions  
        cols = 4   
        row_height = thresh.shape[0] // rows
        col_width = thresh.shape[1] // cols
        selected_answers = []

        for i in range(rows):
            max_pixels = 0
            selected_option = -1
            for j in range(cols):
                box = thresh[
                    i * row_height:(i + 1) * row_height,
                    j * col_width:(j + 1) * col_width
                ]
                non_zero_pixels = cv2.countNonZero(box)
                if non_zero_pixels > max_pixels:
                    max_pixels = non_zero_pixels
                    selected_option = j
            selected_answers.append(selected_option)

        score = sum(1 for i, ans in enumerate(selected_answers) if ans == answer_key_list[i])

       
        for i, option in enumerate(selected_answers):
            if option != -1:
                center_x = option * col_width + col_width // 2
                center_y = i * row_height + row_height // 2
                color = (0, 255, 0) if option == answer_key_list[i] else (0, 0, 255)
                cv2.circle(warped, (center_x, center_y), 15, color, -1)

      
        output_path = os.path.join(OUTPUT_DIR, f"processed_{datetime.now().timestamp()}.jpg")
        cv2.imwrite(output_path, warped)

       
        with open(output_path, "rb") as img_file:
            encoded_image = base64.b64encode(img_file.read()).decode('utf-8')

    
        result = {
            "score": score,
            "totalQuestions": num_questions,
            "selectedAnswers": selected_answers,
            "imageBase64": encoded_image  
        }
        return JSONResponse(result)

    except Exception as e:
        print(f"Error: {e}")
        return JSONResponse({"error": str(e)}, status_code=500)
