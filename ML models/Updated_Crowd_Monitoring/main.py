import cv2
import numpy as np
from ultralytics import YOLO
import time

# Load YOLOv8 nano model
model = YOLO("./yolov8n.pt")  # Ensure you have the model file in the same directory

# Open webcam (0) or replace with video path
cap = cv2.VideoCapture(1)

# Threshold for crowd alert
CROWD_THRESHOLD = 15

prev_time = 0

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Resize for faster processing
    frame = cv2.resize(frame, (1020, 600))

    # YOLO prediction
    results = model(frame, stream=True)

    person_count = 0

    for r in results:
        boxes = r.boxes

        for box in boxes:
            cls = int(box.cls[0])

            # Class 0 = person
            if cls == 0:
                person_count += 1

                x1, y1, x2, y2 = map(int, box.xyxy[0])
                conf = float(box.conf[0])

                # Draw bounding box
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)
                cv2.putText(frame, f"{conf:.2f}",
                            (x1, y1-5),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.5, (0,255,0), 1)

    # Display person count
    cv2.putText(frame, f"People Count: {person_count}",
                (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                1.2, (0,0,255), 3)

    # Crowd Alert
    if person_count > CROWD_THRESHOLD:
        cv2.putText(frame, "ALERT: HIGH CROWD DENSITY!",
                    (20, 80),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1, (0,0,255), 3)

    # FPS Calculation
    curr_time = time.time()
    fps = 1 / (curr_time - prev_time)
    prev_time = curr_time

    cv2.putText(frame, f"FPS: {int(fps)}",
                (850, 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                1, (255,0,0), 2)

    cv2.imshow("Crowd Monitoring System", frame)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()