import runpy
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODULE = runpy.run_path(str(PROJECT_ROOT / "classroom_deliverable_share.py"))
ArtifactResult = MODULE["ArtifactResult"]
build_additional_comments = MODULE["build_additional_comments"]
build_submission_followup_comments = MODULE["build_submission_followup_comments"]


class CommentRuleTests(unittest.TestCase):
    def test_valid_primary_submission_ignores_extra_zip(self) -> None:
        comments = build_additional_comments(
            [
                ArtifactResult(
                    key="source_code",
                    label="소스코드",
                    status="pass",
                    candidate_count=2,
                    valid_count=1,
                    required_min_count=1,
                    bad_kind_count=1,
                    bad_extension_count=0,
                    bad_filename_count=1,
                    source_code_zip_count=1,
                    candidate_names=[],
                    notes=[],
                )
            ]
        )
        self.assertEqual(comments, [])

    def test_missing_comment_has_no_deadline_phrase(self) -> None:
        comments = build_additional_comments(
            [
                ArtifactResult(
                    key="source_code",
                    label="소스코드",
                    status="missing",
                    candidate_count=0,
                    valid_count=0,
                    required_min_count=1,
                    bad_kind_count=0,
                    bad_extension_count=0,
                    bad_filename_count=0,
                    source_code_zip_count=0,
                    candidate_names=[],
                    notes=[],
                )
            ]
        )
        self.assertEqual(comments, ["필수 산출물인 '소스코드'가 누락되었습니다."])

    def test_followup_comments_are_fact_only(self) -> None:
        comments = build_submission_followup_comments("CREATED", "")
        self.assertEqual(
            comments,
            [
                "클래스룸 제출 상태가 미제출로 확인됩니다.",
                "공유할 제출물 폴더가 로컬에서 확인되지 않았습니다.",
            ],
        )


if __name__ == "__main__":
    unittest.main()
