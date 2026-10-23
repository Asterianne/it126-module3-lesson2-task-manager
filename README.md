IT 126 – Module 3 Lesson 2

Activity: Investigating Data Persistence

Analysis

1. What happened to the task titles when you added them to the list?

The task titles were added to the list and displayed on the screen.

2. Why could the application display the tasks while it was running?

The tasks were stored in a list in memory, so the application could display them while it was running.

3. What happened after the application process ended and the application was relaunched?

The tasks stored in memory disappeared because they were not saved permanently.

4. Would keeping the list inside a StatefulWidget automatically make the tasks persistent? Explain your answer.

No. A StatefulWidget keeps data while the app is running, but the data is lost when the application process ends.

5. What would the application need to do to preserve the tasks between sessions?

The application needs to save the tasks in persistent storage, such as an SQLite database, and retrieve them when it opens again.

6. If the application eventually stored hundreds or thousands of tasks, what problems might arise from managing all the data manually in memory?

Managing many tasks in memory could use more RAM and make the data harder to organize, update, and maintain.

7. How could separating the operations that save and retrieve tasks from the UI make the application easier to maintain?

It keeps the database operations separate from the UI, making the code easier to read, test, update, and maintain.